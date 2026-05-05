# Sabiqe LMS — Project Bootstrap Guide

> Everything needed to go from a blank Laravel 13 install to a running
> multi-tenant LMS skeleton. Follow steps in order.

---

## Prerequisites

```bash
PHP    >= 8.3
Composer >= 2.x
Node   >= 20.x (for Horizon dashboard assets)
Redis  (queue driver + cache)
MySQL  >= 8.0 or PostgreSQL >= 15
```

---

## 1. Create Laravel Project

```bash
composer create-project laravel/laravel sabiqe-lms
cd sabiqe-lms
```

---

## 2. Install All Packages

```bash
# Multi-tenancy
composer require stancl/tenancy

# Auth
composer require laravel/passport

# Roles & Permissions
composer require spatie/laravel-permission

# Billing
composer require laravel/cashier

# Activity Log
composer require spatie/laravel-activitylog

# Queue Dashboard
composer require laravel/horizon

# Dev tools
composer require --dev laravel/telescope
composer require --dev barryvdh/laravel-debugbar
```

---

## 3. Environment Setup

```env
# .env

APP_NAME="Sabiqe LMS"
APP_ENV=local
APP_URL=http://sabiqe.test

# Central DB
DB_CONNECTION=central
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=sabiqe_central
DB_USERNAME=root
DB_PASSWORD=

# Tenant DBs are created automatically by stancl/tenancy
# Prefix for tenant databases:
TENANCY_DB_PREFIX=sabiqe_tenant_

# Redis (Queue + Cache)
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
QUEUE_CONNECTION=redis
CACHE_DRIVER=redis
SESSION_DRIVER=redis

# Central domain
CENTRAL_DOMAIN=sabiqe.test

# Storage
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=sabiqe-media
```

---

## 4. Database Configuration

Add the `central` connection to `config/database.php`:

```php
'connections' => [

    'central' => [
        'driver'    => 'mysql',
        'host'      => env('DB_HOST', '127.0.0.1'),
        'port'      => env('DB_PORT', '3306'),
        'database'  => env('DB_DATABASE', 'sabiqe_central'),
        'username'  => env('DB_USERNAME', 'root'),
        'password'  => env('DB_PASSWORD', ''),
        'charset'   => 'utf8mb4',
        'collation' => 'utf8mb4_unicode_ci',
        'prefix'    => '',
        'strict'    => true,
        'engine'    => null,
    ],

    // stancl/tenancy registers tenant connections dynamically at runtime
    // Do NOT add a static 'tenant' connection here.
],

'default' => env('DB_CONNECTION', 'central'),
```

---

## 5. Configure stancl/tenancy

```bash
php artisan tenancy:install
```

Edit `config/tenancy.php`:

```php
return [
    'tenant_model'  => \App\Models\Central\Tenant::class,

    'central_domains' => [
        env('CENTRAL_DOMAIN', 'sabiqe.test'),
    ],

    'bootstrappers' => [
        \Stancl\Tenancy\Bootstrappers\DatabaseTenancyBootstrapper::class,
        \Stancl\Tenancy\Bootstrappers\CacheTenancyBootstrapper::class,
        \Stancl\Tenancy\Bootstrappers\QueueTenancyBootstrapper::class,
    ],

    'database' => [
        'central_connection'  => env('DB_CONNECTION', 'central'),
        'template_tenant_connection' => 'tenant',
    ],

    'migration_parameters' => [
        '--path'     => ['database/migrations/tenant'],
        '--realpath' => true,
    ],
];
```

---

## 6. Configure Spatie Permission

Publish and edit `config/permission.php`:

```php
// CRITICAL — must override for BINARY(16) UUIDs
'column_names' => [
    'role_morph_key'  => 'model_id',
    'model_morph_key' => 'model_id',
],

'teams' => false,   // tenancy is DB-level, not Spatie teams

'cache' => [
    'expiration_time'  => \DateInterval::createFromDateString('24 hours'),
    'key'              => 'spatie.permission.cache',
    'store'            => 'default',
],
```

---

## 7. Install Passport

```bash
# Central DB setup
php artisan migrate --path=database/migrations/central

# Install Passport on central DB
php artisan passport:install

# After tenant provisioning, run per tenant:
# php artisan tenants:run "passport:install"
```

---

## 8. Configure Horizon

```bash
php artisan horizon:install
```

Edit `config/horizon.php` — define queue groups:

```php
'environments' => [
    'production' => [
        'supervisor-default' => [
            'connection' => 'redis',
            'queue'      => ['default'],
            'balance'    => 'auto',
            'processes'  => 5,
            'tries'      => 3,
        ],
        'supervisor-reports' => [
            'connection' => 'redis',
            'queue'      => ['reports'],
            'balance'    => 'simple',
            'processes'  => 2,
            'timeout'    => 300,
            'tries'      => 3,
        ],
        'supervisor-notifications' => [
            'connection' => 'redis',
            'queue'      => ['notifications'],
            'balance'    => 'auto',
            'processes'  => 5,
            'tries'      => 3,
        ],
        'supervisor-media' => [
            'connection' => 'redis',
            'queue'      => ['media'],
            'balance'    => 'simple',
            'processes'  => 3,
            'tries'      => 2,
        ],
        'supervisor-imports' => [
            'connection' => 'redis',
            'queue'      => ['imports'],
            'balance'    => 'simple',
            'processes'  => 2,
            'timeout'    => 600,
            'tries'      => 2,
        ],
    ],
    'local' => [
        'supervisor-local' => [
            'connection' => 'redis',
            'queue'      => ['default', 'reports', 'notifications', 'media', 'imports'],
            'balance'    => 'simple',
            'processes'  => 4,
            'tries'      => 3,
        ],
    ],
],
```

---

## 9. Set Up Migration Directories

```bash
mkdir -p database/migrations/central
mkdir -p database/migrations/tenant
```

Move the default Laravel migrations into `central/`:
```bash
mv database/migrations/*.php database/migrations/central/
```

---

## 10. Service Providers

Register module service providers in `bootstrap/providers.php`:

```php
return [
    App\Providers\AppServiceProvider::class,
    App\Providers\AuthServiceProvider::class,
    App\Modules\Core\Providers\CoreServiceProvider::class,
    App\Modules\Auth\Providers\AuthModuleServiceProvider::class,
    App\Modules\Branches\Providers\BranchServiceProvider::class,
    // ... one per module
];
```

Each module's ServiceProvider registers its routes, bindings, and observers:

```php
<?php

namespace App\Modules\Branches\Providers;

use Illuminate\Support\ServiceProvider;

class BranchServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        $this->loadRoutesFrom(__DIR__ . '/../Routes/api.php');
    }

    public function register(): void
    {
        $this->app->scoped(
            \App\Modules\Branches\Services\BranchService::class,
        );
    }
}
```

---

## 11. Scheduled Commands

Add to `routes/console.php` or `app/Console/Kernel.php`:

```php
Schedule::job(new MarkOverdueInvoicesJob())->dailyAt('01:00');
Schedule::command('horizon:snapshot')->everyFiveMinutes();
Schedule::command('activitylog:clean')->weekly();
Schedule::command('telescope:prune --hours=48')->daily();

// Purge old tenant audit logs (keep 90 days)
Schedule::command('tenant-audit:prune --days=90')->weekly();
```

---

## 12. First Run

```bash
# Run central DB migrations
php artisan migrate --path=database/migrations/central

# Start queue worker
php artisan horizon

# Start dev server
php artisan serve
```

### Create the first tenant (via Tinker or seed):

```php
php artisan tinker

$provisioningService = app(\App\Modules\Schools\Services\TenantProvisioningService::class);
$tenant = $provisioningService->provision([
    'name'         => 'Al Nour School',
    'tenant_type'  => 1,   // School
    'domain'       => 'alnour.sabiqe.test',
    'locale'       => 'ar',
    'currency'     => 'EGP',
    'timezone'     => 'Africa/Cairo',
    'country'      => 'EG',
]);

echo $tenant->tenant_id;
```

After creation — the tenant's DB is auto-created, migrated, and seeded with
default roles and permissions via `TenantProvisioningService`.

---

## 13. Useful Artisan Commands

```bash
# Run a migration on ALL tenants
php artisan tenants:run "migrate"

# Run a specific migration on one tenant
php artisan tenants:artisan "migrate --path=database/migrations/tenant/2026_04_add_..." --tenant={id}

# Seed a specific tenant
php artisan tenants:run "db:seed --class=LookupSeeder"

# Flush Spatie permission cache (tenant-aware)
php artisan permission:cache-reset

# Monitor queues
php artisan horizon:status

# Clear all caches
php artisan optimize:clear
```

---

## 14. Directory Creation Script

Run once after cloning:

```bash
#!/bin/bash
mkdir -p app/Models/Central
mkdir -p app/Models/Tenant
mkdir -p app/Http/Controllers/Central
mkdir -p app/Http/Controllers/Tenant
mkdir -p app/Http/Requests/Central
mkdir -p app/Http/Requests/Tenant
mkdir -p app/Http/Resources/Central
mkdir -p app/Http/Resources/Tenant
mkdir -p app/Services/Central
mkdir -p app/Services/Tenant
mkdir -p database/migrations/central
mkdir -p database/migrations/tenant
mkdir -p database/seeders/central
mkdir -p database/seeders/tenant

modules=(Core Auth Users Schools Branches Stages Grades Classrooms Sections \
         Teachers Students Parents Subjects AcademicYears Attendance Quizzes \
         Homeworks StudyMaterials Timetable OnlineClasses WeeklyPlans \
         Notifications Fees Reports Settings Media)

for module in "${modules[@]}"; do
  mkdir -p "app/Modules/$module/Controllers"
  mkdir -p "app/Modules/$module/Services"
  mkdir -p "app/Modules/$module/Requests"
  mkdir -p "app/Modules/$module/Resources"
  mkdir -p "app/Modules/$module/Routes"
  mkdir -p "app/Modules/$module/Providers"
  if [[ "$module" != "Core" ]]; then
    mkdir -p "app/Modules/$module/Jobs"
  fi
done

echo "All module directories created."
```

Save as `scripts/bootstrap.sh` and run `chmod +x scripts/bootstrap.sh && ./scripts/bootstrap.sh`.