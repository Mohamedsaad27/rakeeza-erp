# P0 Foundation — Core Infrastructure & Module Scaffolding

All migrations have been successfully created and applied. This plan covers the next steps: fixing the module generator, creating missing modules, standardizing all modules' folder structure, and building the **P0 Foundation** (Core traits, ActivityLog, HasUuid).

---

## User Review Required

> [!IMPORTANT]
> **Model folder location discrepancy:** The `MakeModule` command currently places Models at `Infrastructure/Persistence/Models/`, but the CURSOR_RULES mandate `Infrastructure/Database/Models/`. This plan will:
> 1. Fix the `MakeModule` command to use the correct path (`Infrastructure/Database/Models/`).
> 2. **Not** move existing `Persistence/Models/` directories yet — they are currently empty. The correct path will be used going forward.

> [!WARNING]
> **The `MakeModule` command has a bug:** It uses `base_path("App/Modules/{$name}")` (capital `A`) instead of `base_path("app/Modules/{$name}")` (lowercase `a`). On Windows this works by accident, but on Linux it would create modules in the wrong folder. This plan fixes it.

---

## Open Questions

> [!IMPORTANT]
> 1. **Spatie Activity Log vs Custom ActivityLog:** The `plan.md` mentions `Spatie Laravel Activitylog` but the CURSOR_RULES specify a **custom `ActivityLog` module**. This plan follows the CURSOR_RULES (custom module). Is that correct?
> 2. **Laravel Passport vs JWT (tymon/jwt-auth):** The `plan.md` mentions Passport, but CURSOR_RULES mandates JWT via `tymon/jwt-auth`. This plan follows the CURSOR_RULES. Correct?
> 3. **Missing modules:** The CURSOR_RULES list `Users`, `Roles`, `Plans`, and `Billing` as separate modules. Should I create all four now, or only `Users` and `Roles` (needed for Phase 1)?

---

## 🆕 Database Schema — Critical Fixes Required

> [!CAUTION]
> **These bugs will cause migration failures. Fix them before running `php artisan migrate`.**

### Bug 1 — Broken foreign key references (will crash on Linux/MySQL strict mode)

The following tables reference `tenants (\`id\`)` but the primary key column is `tenant_id`. MySQL will reject the FK constraint because the column `id` does not exist.

**Affected tables:** `domains`, `subscriptions`, `invoices`, `platform_notification_targets`

**Fix:** Replace every `REFERENCES \`tenants\` (\`id\`)` with `REFERENCES \`tenants\` (\`tenant_id\`)` in those four migration files.

```php
// ❌ Wrong — column `id` doesn't exist on tenants
FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE

// ✅ Correct
FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`tenant_id`) ON DELETE CASCADE
```

### Bug 2 — `migrations` table primary key mismatch

The `migrations` table declares `id INT AUTO_INCREMENT` but names its primary key `migration_id`. MySQL will reject this because the PK references a column that was never declared.

```php
// ❌ Wrong
Schema::create('migrations', function (Blueprint $table) {
    $table->integer('id')->autoIncrement(); // column is `id`
    $table->primary('migration_id');        // but PK references `migration_id`
});

// ✅ Correct — Laravel manages this table automatically; do not create a custom migration for it
// If you need a custom migrations table, be consistent:
$table->id('migration_id'); // declares AND names the column
```

### Bug 3 — `password_resets` has no `tenant_id` scope

`users.email` is only unique **per tenant** (composite unique key `tenant_id + email`), not globally. A reset token issued for `user@example.com` at tenant A could be consumed by a user at tenant B with the same email.

**Fix:** Add `tenant_id` to `password_resets` and validate it during reset token lookup.

```php
// Add to password_resets migration
$table->uuid('tenant_id')->index()->nullable(); // nullable to support platform_users resets too

// In your PasswordResetRepository, always scope by tenant:
PasswordReset::where('email', $email)
    ->where('tenant_id', app('tenant_id'))
    ->where('expires_at', '>', now())
    ->first();
```

### Bug 4 — Denormalized balance fields will drift

Both `contacts.balance` and `accounts.balance` are described as cached values derived from transactions, but no trigger, database event, or check constraint enforces this. They will silently diverge from the real totals.

**Recommended fix options (pick one):**

| Option | Pros | Cons |
|--------|------|------|
| **MySQL AFTER INSERT/UPDATE trigger** on `tenant_payment_transactions` | Enforced at DB level, zero app code | Harder to test, couples DB to logic |
| **Repository method** that recalculates balance on every write | Testable, explicit | Risk of forgetting to call it |
| **Nightly reconciliation job** (queue) | Non-blocking, easy rollback | Balance can be stale intra-day |

> For an ERP context where AR/AP accuracy is critical, a trigger + a nightly reconciliation job together is the safest approach.

---

## 🆕 Additional Architecture Recommendations

### 1. Add `tenant_id` to the `notifications` table

The `notifications` table is described as tenant-neutral, but without a `tenant_id` index, bulk-deleting or querying notifications during tenant offboarding requires a full JOIN to the notifiable model. Add a nullable `tenant_id` column with an index for operational efficiency.

```php
// In the notifications migration, add:
$table->uuid('tenant_id')->nullable()->index();
```

### 2. Deduplicate tenant logo storage

Both `tenants.logo` and `tenant_settings.logo` store a logo path. Pick one canonical location (recommend `tenant_settings.logo` since it holds all other branding), and either drop `tenants.logo` or make it a computed accessor that reads from settings.

### 3. Add warehouse zone / bin-location tables

The CURSOR_RULES mention `warehouse_locations` as a tenant table, but the schema only has `warehouses`. Without bin-level tracking, multi-location warehouses cannot support pick-lists or slot-based stock queries.

```php
// Suggested addition to the Inventory module migration
Schema::create('warehouse_zones', function (Blueprint $table) {
    $table->uuid('warehouse_zone_id')->primary();
    $table->uuid('tenant_id')->index();
    $table->uuid('warehouse_id');
    $table->string('name_ar', 150);
    $table->string('name_en', 150);
    $table->string('code', 50)->nullable();
    $table->boolean('is_active')->default(true);
    $table->timestamps();
    $table->softDeletes();

    $table->foreign('warehouse_id')->references('warehouse_id')->on('warehouses')->onDelete('cascade');
});
```

### 4. Planned modules to add (post-P0)

These are not yet in the schema but are natural extensions based on the existing data model:

| Module | Depends on | Effort |
|--------|-----------|--------|
| **Promotions / discount rules engine** | Products, Contacts, Sales | Medium |
| **Fixed assets & depreciation** | Finance, chart_of_accounts | Medium |
| **Delivery & route management** | Sales, Employees | High |
| **Customer loyalty & points ledger** | Contacts, Sales | Low |
| **Online storefront** | Products, Orders, Contacts | High |
| **Helpdesk / support tickets** | Contacts, Users | Medium |

---

## Proposed Changes

### 1. Fix `MakeModule` Command

#### [MODIFY] [MakeModule.php](file:///c:/laragon/www/rakeeza-erp/app/Console/Commands/MakeModule.php)
- Fix `base_path("App/Modules/...")` → `base_path("app/Modules/...")` (lowercase `a`)
- Change `Infrastructure/Persistence/Models` → `Infrastructure/Database/Models` (per CURSOR_RULES)
- Change `Infrastructure/Persistence/Repositories` → `Infrastructure/Persistence` (flatten)
- Add `Infrastructure/Database/Seeders` and `Infrastructure/Database/Factories` directories
- Add `Infrastructure/Notifications` directory

---

### 2. Create Missing Modules

Run `php artisan make:module` for the following modules that are in the CURSOR_RULES but don't exist yet:

#### [NEW] `Users` module — Tenant user CRUD & profile management
#### [NEW] `Roles` module — Role & permission CRUD & assignment

> These two are needed for Phase 1. `Plans` and `Billing` can wait for Phase P7.

---

### 3. Core Module — Foundation Traits & Helpers

#### [NEW] [HasUuid.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/Core/Infrastructure/Traits/HasUuid.php)
- UUID auto-generation trait for all models (as defined in CURSOR_RULES Section 5)
- Uses `Illuminate\Support\Str::uuid()` on the `creating` event

#### [NEW] [BelongsToTenant.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/Core/Infrastructure/Traits/BelongsToTenant.php)
- Auto-scopes queries by `tenant_id` from `app('tenant_id')`
- Automatically sets `tenant_id` on `creating` event
- Adds a global scope to filter by tenant

> [!IMPORTANT]
> **Global scope caveat:** The `BelongsToTenant` global scope will silently exclude records in background jobs unless you call `app()->instance('tenant_id', $this->tenantId)` at the start of every job's `handle()` method. See CURSOR_RULES Section 14 for the job template. Forgetting this is a common silent-data-loss bug.

#### [NEW] [ScopeTenant.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/Core/Presentation/Http/Middleware/ScopeTenant.php)
- Middleware that reads `tenant_id` from the authenticated JWT user
- Binds it to the service container as `app('tenant_id')`
- Returns 401 if tenant not resolved

#### [NEW] [ForbiddenException.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/Core/Application/Exceptions/ForbiddenException.php) — already exists, verify content

#### [NEW] [NotFoundException.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/Core/Application/Exceptions/NotFoundException.php)
- Generic 404 exception extending `BaseException`

#### [NEW] [ValidationException.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/Core/Application/Exceptions/ValidationException.php)
- Wraps Laravel's built-in `ValidationException` into the project's typed exception hierarchy
- Ensures all validation errors flow through the same `ApiResponse::error()` shape

#### [NEW] [PlanLimitException.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/Core/Application/Exceptions/PlanLimitException.php)
- Thrown when a tenant exceeds a `plan_limits` quota (e.g. `max_users`, `max_branches`, `max_products`)
- Returns HTTP 402 with a machine-readable `limit_key` so the frontend can show an upgrade prompt

```php
throw new PlanLimitException(
    limitKey: 'max_users',
    current: 10,
    allowed: 10,
);
// → 402 { "status": false, "message": "Plan limit reached: max_users", "limit_key": "max_users" }
```

---

### 4. ActivityLog Module — Full Implementation

Per CURSOR_RULES Section 18, this is a **P0 dependency** — every module depends on it.

#### [NEW] [TenantAuditLog.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/ActivityLog/Infrastructure/Database/Models/TenantAuditLog.php)
- Eloquent model for `tenant_audit_logs` table (maps to `activity_log` table in schema v5)
- Uses `HasUuid`, `BelongsToTenant` traits
- Primary key: `activity_lo_id`

> [!NOTE]
> The schema v5 table is named `activity_log` (singular) with PK `activity_lo_id`. The model name and interface should abstract over this — consumers call `LogActivityUseCase`, not the table directly.

#### [NEW] [AuditLog.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/ActivityLog/Infrastructure/Database/Models/AuditLog.php)
- Eloquent model for central `audit_logs` table
- Uses `HasUuid` trait (no tenant scoping)

#### [NEW] [ActivityLogRepositoryInterface.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/ActivityLog/Domain/Interfaces/ActivityLogRepositoryInterface.php)
- `logTenantActivity(LogActivityDTO $dto): void`
- `logCentralActivity(LogActivityDTO $dto): void`

#### [NEW] [ActivityLogRepository.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/ActivityLog/Infrastructure/Persistence/ActivityLogRepository.php)
- Implements the interface using Eloquent models
- Writes are **fire-and-forget** — wrap in a queued job so a logging failure never breaks the main transaction

```php
// Preferred: dispatch to the 'default' queue so logging is async
dispatch(fn () => $this->activityLogRepo->logTenantActivity($dto))->onQueue('default');
```

#### [NEW] [LogActivityUseCase.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/ActivityLog/Application/UseCases/LogActivityUseCase.php)
- Orchestrates logging activity to the audit log
- Called from every other module's data-mutating use cases

#### [NEW] [LogActivityDTO.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/ActivityLog/Application/DTOs/LogActivityDTO.php)
- DTO for activity log entries: `event`, `entityType`, `entityId`, `tenantId`, `userId`, `payload`

```php
readonly class LogActivityDTO
{
    public function __construct(
        public string  $event,       // e.g. 'contact.created'
        public string  $entityType,  // e.g. 'contact'
        public string  $entityId,
        public string  $tenantId,
        public ?string $userId    = null,
        public array   $payload   = [],   // before/after diff as JSON-serializable array
        public ?string $ipAddress = null,
        public ?string $module    = null, // 'sales' | 'inventory' | 'hr' | etc.
    ) {}
}
```

#### [MODIFY] [ActivityLogServiceProvider.php](file:///c:/laragon/www/rakeeza-erp/app/Modules/ActivityLog/Infrastructure/Providers/ActivityLogServiceProvider.php)
- Bind `ActivityLogRepositoryInterface` → `ActivityLogRepository`

---

## 🆕 Guard Configuration — Prevent Cross-Guard Token Leakage

Add the following to `config/auth.php` to formally separate the two JWT guards. Without this, a platform_user's token could (in theory) be accepted by the `api` guard if both use the same secret.

```php
// config/auth.php
'guards' => [
    'api' => [
        'driver'   => 'jwt',
        'provider' => 'users',       // App\Modules\Auth\Infrastructure\Database\Models\User
    ],
    'platform' => [
        'driver'   => 'jwt',
        'provider' => 'platform_users', // App\Modules\PlatformUsers\Infrastructure\Database\Models\PlatformUser
    ],
],

'providers' => [
    'users'          => ['driver' => 'eloquent', 'model' => \App\Modules\Auth\Infrastructure\Database\Models\User::class],
    'platform_users' => ['driver' => 'eloquent', 'model' => \App\Modules\PlatformUsers\Infrastructure\Database\Models\PlatformUser::class],
],
```

Configure `tymon/jwt-auth` to use separate secrets per guard via `config/jwt.php` or environment variables:

```env
JWT_SECRET=<tenant_secret>
JWT_PLATFORM_SECRET=<platform_secret>
```

---

## Verification Plan

### Automated Tests

```bash
# Verify no syntax errors in new files
php artisan tinker --execute="echo 'OK';"

# Verify all module providers load correctly
php artisan about

# Verify the MakeModule fix works
php artisan make:module TestModule
# Then delete it after verifying

# Verify ActivityLog can be instantiated
php artisan tinker --execute="app(App\Modules\ActivityLog\Application\UseCases\LogActivityUseCase::class);"

# 🆕 Verify tenant guard rejects platform tokens
php artisan tinker --execute="auth('api')->user();"  # should return null with a platform token

# 🆕 Verify BelongsToTenant scope is applied
php artisan tinker --execute="
  app()->instance('tenant_id', 'test-uuid');
  \$sql = App\Modules\Contacts\Infrastructure\Database\Models\Contact::toSql();
  echo str_contains(\$sql, 'tenant_id') ? 'SCOPED OK' : 'SCOPE MISSING';
"
```

### Manual Verification

- Confirm all modules are discovered by the `ModuleServiceProvider`
- Check that `HasUuid` generates UUIDs on model creation
- Check that `BelongsToTenant` properly scopes queries
- **🆕 Verify FK fixes:** Run `php artisan migrate:fresh` on a clean MySQL instance and confirm no FK errors on `domains`, `subscriptions`, `invoices`, or `platform_notification_targets`
- **🆕 Verify password reset scoping:** Attempt a reset for an email that exists under two different tenants and confirm each tenant only resolves their own token
- **🆕 Verify plan limit check:** Seed a tenant with `max_users = 2`, create 2 users, then attempt a third and confirm a `402 PlanLimitException` is returned

---

## Build Order (Updated)

| Step | Task | Blocks |
|------|------|--------|
| 1 | Apply DB schema bug fixes (FKs, password_resets scope, migrations table) | Everything |
| 2 | Fix `MakeModule` command (path casing + folder structure) | All new modules |
| 3 | Build `Core` module (HasUuid, BelongsToTenant, ScopeTenant, exceptions) | All tenant modules |
| 4 | Configure JWT guards (`api` + `platform`) in `config/auth.php` | Auth module |
| 5 | Build `ActivityLog` module (async, DTO, repository, use case) | All data-mutating modules |
| 6 | Create `Users` and `Roles` modules (scaffold only) | Phase P1 |
| 7 | Write automated tests for guard isolation and tenant scope | CI pipeline |