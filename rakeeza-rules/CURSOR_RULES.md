# Rakeeza ERP — Cursor AI Rules (Master File)

> **Read this file first on every task.**
> This is a multi-tenant commercial/trading ERP platform built on Laravel 13.
> Every rule here is mandatory unless a module-level file overrides it.
> Per-module rules live in `.cursor/rules/`.

---

## 1. Project Identity

| Key | Value |
|-----|-------|
| Product | Rakeeza ERP |
| Framework | Laravel 13 |
| Architecture | Custom Clean Architecture — Module-based |
| Multi-tenancy | One physical database; central tables + tenant-scoped tables coexist. All tenant tables have `tenant_id` |
| Auth | JWT (`tymon/jwt-auth`) — guards: `platform` (central) and `api` (tenant) |
| Authorization | `spatie/laravel-permission` scoped per tenant |
| Multilingual | No packages — Middleware only (`SetLocale`) [Arabic - English] |
| Billing | `laravel/cashier` |
| Activity Log | Custom `ActivityLog` module (all other modules depend on it) |
| Queues | Laravel Horizon (Redis) |
| Notifications | Laravel Notifications (email, SMS, in-app, FCM push) |
| Primary Keys | `CHAR(36)` UUID Standard from Laravel — no auto-increment IDs |
| Languages | Arabic (primary) + English — all user-facing fields are bilingual |

---

## 2. Database Architecture — The Most Important Rule

There is **one physical database**. Central tables and tenant-scoped tables coexist in it.
**Never create a separate database per tenant.**

### Central Tables
Managed by the single, default database connection.
Contains platform-level data shared across tenants.

```
Central tables: tenants, plans, plan_features, features,
                subscriptions, subscription_history,
                invoices, payments, payment_transactions, refunds,
                platform_users, domains,
                contact_requests, demo_requests,
                platform_notifications, platform_notification_targets,
                audit_logs
```

### Tenant-Scoped Tables
Every tenant table has `tenant_id CHAR(36) NOT NULL` as the **second column** after the primary key.
All queries **must** scope on `tenant_id`.

```
Tenant tables (all include tenant_id):

Auth & Users:   users, roles, permissions, role_user, permission_user, permission_role
CRM:            contacts, contact_groups, contact_addresses, contact_notes, lead_activities
Products:       products, brands, categories, units, product_unit_details,
                product_variants, product_branch_details
Inventory:      warehouses, warehouse_locations, stock_movements,
                inventory_adjustments, stock_transfers
Sales:          transactions (type=sell), transaction_sell_lines,
                sales_returns, sales_return_lines, pos_sessions
Purchasing:     transactions (type=purchase), transaction_purchase_lines,
                purchase_returns, purchase_return_lines, purchase_orders
Finance:        chart_of_accounts, journal_entries, journal_entry_lines,
                accounts, transfers
Payments:       payments, payment_transactions
Expenses:       expenses, expense_categories
HR:             employees, departments, designations, attendances,
                leaves, leave_types, payrolls, payroll_items, salary_structures
Settings:       settings, tax_rates, currencies, business_locations
Media:          media_files
Audit:          tenant_audit_logs
```

### Rules for DB access
- Tenant models → `App\Modules\{Module}\Infrastructure\Database\Models`
- Central models → `App\Modules\{CentralModule}\Infrastructure\Database\Models`
- **Never** query a tenant table without scoping by `tenant_id`.
- **Never** set a connection name or specify a `$connection` property on any model (central or tenant). All models use the single default database connection.

---

## 3. Directory Structure

```
app/
├── Modules/
│   ├── Core/               ← Shared base classes, traits, helpers (HasUuid, ApiResponse, etc.)
│   │
│   ├── — Central Modules —
│   ├── Tenants/            ← Tenant CRUD, onboarding, provisioning, domain management
│   ├── PlatformUsers/      ← Super-admin and support staff
│   ├── Plans/              ← Subscription tier management
│   ├── Billing/            ← Cashier integration, invoices, payments, refunds
│   │
│   ├── — Tenant Modules —
│   ├── Auth/               ← Login, register, password reset, token refresh
│   ├── Users/              ← Tenant user CRUD, profile management
│   ├── Roles/              ← Role & permission CRUD, assignment
│   ├── Contacts/           ← Customers & suppliers (CRM)
│   ├── Products/           ← Product catalog: brands, categories, units, variants
│   ├── Inventory/          ← Warehouses, stock movements, adjustments, transfers
│   ├── Sales/              ← Sales invoices, returns, POS, quotations
│   ├── Purchasing/         ← Purchase orders, invoices, returns
│   ├── Finance/            ← Chart of accounts, journal entries, transfers
│   ├── Payments/           ← Customer & supplier payment recording
│   ├── Expenses/           ← Expense tracking & categorization
│   ├── HR/                 ← Employees, attendance, leave, payroll
│   ├── Reports/            ← Sales, purchase, inventory, financial, HR reports
│   ├── Settings/           ← Tax rates, currencies, business locations, tenant config
│   ├── Notifications/      ← In-app, email, SMS, push notifications
│   └── ActivityLog/        ← Custom audit trail (P0 — all modules depend on it)

database/
├── migrations/
│   ├── central/            ← Central table migrations only
│   └── tenant/             ← Tenant-scoped table migrations only
└── seeders/
    ├── central/
    └── tenant/
```

Each module follows this **Clean Architecture** internal structure:

```
Modules/Contacts/
│
├── Application/
│   ├── DTOs/
│   │   ├── CreateContactDTO.php
│   │   └── UpdateContactDTO.php
│   ├── Exceptions/
│   │   └── ContactNotFoundException.php
│   └── UseCases/
│       ├── CreateContactUseCase.php
│       ├── UpdateContactUseCase.php
│       ├── DeleteContactUseCase.php
│       └── GetContactsUseCase.php
│
├── Domain/
│   ├── Enums/
│   │   └── ContactType.php      ← customer | supplier
│   ├── Interfaces/
│   │   └── ContactRepositoryInterface.php
│   └── Services/
│       └── ContactDomainService.php
│
├── Infrastructure/
│   ├── Config/
│   │   └── contact.php
│   ├── Database/
│   │   ├── Migrations/
│   │   │   └── create_contacts_table.php
│   │   ├── Seeders/
│   │   │   └── ContactSeeder.php
│   │   └── Models/
│   │       └── Contact.php
│   ├── Notifications/
│   │   └── ContactCreatedNotification.php
│   ├── Persistence/
│   │   └── ContactRepository.php
│   ├── Providers/
│   │   └── ContactServiceProvider.php
│   └── ExternalServices/
│       └── (third-party integrations)
│
└── Presentation/
    ├── Http/
    │   ├── Controllers/
    │   │   └── ContactController.php
    │   └── Requests/
    │   │   ├── StoreContactRequest.php
    │   │   └── UpdateContactRequest.php
    │   └── Resources/
    │       └── ContactResource.php
    ├── Resources/
    │   └── lang/
    │       ├── en/messages.php
    │       └── ar/messages.php
    └── Routes/
        └── api.php
```

### Namespace Map

| Layer | Namespace |
|-------|-----------|
| Use Cases | `App\Modules\Contacts\Application\UseCases` |
| DTOs | `App\Modules\Contacts\Application\DTOs` |
| Exceptions | `App\Modules\Contacts\Application\Exceptions` |
| Domain Enums | `App\Modules\Contacts\Domain\Enums` |
| Domain Interfaces | `App\Modules\Contacts\Domain\Interfaces` |
| Domain Services | `App\Modules\Contacts\Domain\Services` |
| Eloquent Model | `App\Modules\Contacts\Infrastructure\Database\Models` |
| Repository | `App\Modules\Contacts\Infrastructure\Persistence` |
| Notifications | `App\Modules\Contacts\Infrastructure\Notifications` |
| Service Provider | `App\Modules\Contacts\Infrastructure\Providers` |
| Controller | `App\Modules\Contacts\Presentation\Http\Controllers` |
| Requests | `App\Modules\Contacts\Presentation\Http\Requests` |
| Resources | `App\Modules\Contacts\Presentation\Resources` |
| Lang | `App\Modules\Contacts\Presentation\Resources\Lang\` |
| Routes | `App\Modules\Contacts\Presentation\Routes` |

---

## 4. Naming Conventions

### Files & Classes
| Type | Convention | Example |
|------|-----------|---------|
| Model | PascalCase singular | `Contact`, `StockMovement` |
| Controller | PascalCase + Controller | `ContactController` |
| Use Case | Verb + Model + UseCase | `CreateContactUseCase` |
| Service | PascalCase + Service | `ContactDomainService` |
| Request | Verb + Model + Request | `StoreContactRequest`, `UpdateContactRequest` |
| Resource | Model + Resource | `ContactResource` |
| Migration | snake_case descriptive | `create_contacts_table` |
| Seeder | Model + Seeder | `ContactSeeder` |
| Job | Verb + Noun + Job | `GenerateSalesReportJob` |
| Event | PastTense noun | `StockAdjusted`, `PaymentRecorded` |
| Listener | On + EventName | `OnStockAdjusted` |

### Database
| Type | Convention | Example |
|------|-----------|---------|
| Table | `snake_case` plural | `contacts`, `stock_movements` |
| Primary Key | `{singular_table}_id` UUID | `contact_id`, `product_id` |
| Foreign Key | `{referenced_table_singular}_id` | `contact_id`, `warehouse_id` |
| Pivot table | `{model_a}_{model_b}` alphabetical | `product_unit_details` |
| Bilingual col | `{name}_ar` / `{name}_en` | `name_ar`, `name_en` |
| Soft delete | `deleted_at TIMESTAMP` | standard Laravel |
| Boolean | `is_{state}` or `has_{feature}` | `is_active`, `is_customer`, `is_supplier` |
| Status enum | `status TINYINT` + PHPDoc | `1=active 2=inactive` |
| Financial | `decimal(15,4)` | `unit_price`, `balance`, `amount` |

### Routes
```
/api/v1/central/...     → Platform admin routes (Central DB)
/api/v1/auth/...        → Tenant auth (login, register, reset)
/api/v1/{module}/...    → Tenant routes (auto-scoped by tenant_id middleware)
```

### Variable & Method Names
- Variables: `camelCase`
- Methods: `camelCase`, verb-first: `createContact()`, `adjustStock()`, `generateReport()`
- Constants: `UPPER_SNAKE_CASE`
- Config keys: `snake_case`

---

## 5. Model Rules

### All Tenant Models

> Models live in `Infrastructure/Database/Models/` inside each module.
> Namespace: `App\Modules\{Module}\Infrastructure\Database\Models`
> **Do NOT set `$connection`** — tenant scoping is handled via `tenant_id` middleware injection.

```php
<?php

namespace App\Modules\Contacts\Infrastructure\Database\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Modules\Core\Traits\HasUuid;

class Contact extends Model
{
    use SoftDeletes, HasUuid;

    protected $primaryKey = 'contact_id';
    protected $keyType    = 'string';
    public $incrementing  = false;

    protected $fillable = [
        'tenant_id',
        'name_ar',
        'name_en',
        'type',          // 1=customer 2=supplier 3=both
        'phone',
        'email',
        'tax_number',
        'credit_limit',
        'is_active',
    ];

    protected $casts = [
        'credit_limit' => 'decimal:4',
        'is_active'    => 'boolean',
        'deleted_at'   => 'datetime',
        'created_at'   => 'datetime',
        'updated_at'   => 'datetime',
    ];

    public function addresses(): HasMany
    {
        return $this->hasMany(ContactAddress::class, 'contact_id', 'contact_id');
    }
}
```

### All Central Models

> Central models live in `Infrastructure/Database/Models/` inside their central module.
> Central models do **NOT** specify a `$connection` property. All tables use the single default connection.

```php
<?php

namespace App\Modules\Tenants\Infrastructure\Database\Models;

use Illuminate\Database\Eloquent\Model;
use App\Modules\Core\Traits\HasUuid;

class Tenant extends Model
{
    use HasUuid;

    protected $primaryKey = 'tenant_id';
    protected $keyType    = 'string';
    public $incrementing  = false;

    protected $fillable = [
        'name',
        'slug',
        'domain',
        'status',
        'plan_id',
        'trial_ends_at',
    ];
}
```

### UUID Trait (Core)

```php
// app/Modules/Core/Infrastructure/Traits/HasUuid.php

use Illuminate\Support\Str;

trait HasUuid
{
    protected static function bootHasUuid(): void
    {
        static::creating(function ($model) {
            if (empty($model->{$model->getKeyName()})) {
                $model->{$model->getKeyName()} = (string) Str::uuid();
            }
        });
    }
}
```

---

## 6. Controller Rules

- Controllers are **thin**. No business logic inside a controller.
- Every controller method calls a Use Case.
- Always use Form Requests for validation — never `$request->validate()` inline.
- Always return via `ApiResponse` helper (see Core module).
- Use Resource classes for all output — never return raw model instances.

```php
<?php

namespace App\Modules\Contacts\Presentation\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Contacts\Presentation\Http\Requests\StoreContactRequest;
use App\Modules\Contacts\Application\UseCases\CreateContactUseCase;
use App\Modules\Contacts\Application\UseCases\GetContactsUseCase;
use App\Modules\Contacts\Presentation\Resources\ContactResource;
use App\Modules\Core\Infrastructure\Helpers\ApiResponse;

class ContactController extends Controller
{
    public function __construct(
        private CreateContactUseCase $createContact,
        private GetContactsUseCase   $getContacts,
    ) {}

    public function store(StoreContactRequest $request): \Illuminate\Http\JsonResponse
    {
        $contact = $this->createContact->execute($request->validated());

        return ApiResponse::success(
            new ContactResource($contact),
            __('contact.created'),
            201
        );
    }

    public function index(): \Illuminate\Http\JsonResponse
    {
        $contacts = $this->getContacts->execute();

        return ApiResponse::paginated(ContactResource::collection($contacts));
    }
}
```

---

## 7. Use Case & Domain Service Rules

### Layers explained

| Layer | Class | Responsibility |
|-------|-------|----------------|
| `Application/UseCases` | `CreateContactUseCase` | Orchestrates: validates input DTO, calls domain service or repo, returns result |
| `Domain/Services` | `ContactDomainService` | Pure domain logic with zero framework dependencies |
| `Infrastructure/Persistence` | `ContactRepository` | Eloquent queries — implements `ContactRepositoryInterface` |

### Rules
- Controllers call **Use Cases only** — never repositories or domain services directly.
- Use Cases inject dependencies via constructor (never `new SomeClass()`).
- Use Cases wrap multi-step DB operations in `DB::transaction()`.
- Use Cases throw typed Exceptions when an error is found.
- Domain Services contain **zero Eloquent** — they operate on plain PHP objects / DTOs.
- Repositories implement the Domain Interface — the Use Case depends on the interface, not the concrete class.
- **Never** access `Request` inside a Use Case.
- **Never** return Eloquent Models from a Use Case — return a DTO or data array.
- **Never** couple Use Cases to Laravel-specific classes (`Collection`, `Response`, etc.).
- **Never** put validation inside a Use Case — validation belongs in FormRequest only.

### Use Case example

```php
<?php

namespace App\Modules\Contacts\Application\UseCases;

use App\Modules\Contacts\Application\DTOs\CreateContactDTO;
use App\Modules\Contacts\Domain\Interfaces\ContactRepositoryInterface;
use App\Modules\ActivityLog\Application\UseCases\LogActivityUseCase;
use Illuminate\Support\Facades\DB;

class CreateContactUseCase
{
    public function __construct(
        private ContactRepositoryInterface $repository,
        private LogActivityUseCase         $logActivity,
    ) {}

    public function execute(array $data): array
    {
        $dto = new CreateContactDTO(...$data);

        $contact = DB::transaction(fn () => $this->repository->create($dto));

        $this->logActivity->execute('contact.created', $contact->contact_id);

        return $contact->toArray();
    }
}
```

### DTO example

```php
<?php

namespace App\Modules\Contacts\Application\DTOs;

readonly class CreateContactDTO
{
    public function __construct(
        public string  $tenant_id,
        public string  $name_ar,
        public string  $name_en,
        public int     $type         = 1,   // 1=customer 2=supplier 3=both
        public ?string $phone        = null,
        public ?string $email        = null,
        public ?string $tax_number   = null,
        public float   $credit_limit = 0,
        public bool    $is_active    = true,
    ) {}
}
```

### Repository Interface (Domain layer)

```php
<?php

namespace App\Modules\Contacts\Domain\Interfaces;

use App\Modules\Contacts\Application\DTOs\CreateContactDTO;
use App\Modules\Contacts\Infrastructure\Database\Models\Contact;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface ContactRepositoryInterface
{
    public function create(CreateContactDTO $dto): Contact;
    public function getAll(string $tenantId, int $perPage = 15): LengthAwarePaginator;
    public function findById(string $tenantId, string $id): Contact;
    public function update(Contact $contact, array $data): Contact;
    public function delete(Contact $contact): void;
}
```

### Repository Implementation (Infrastructure layer)

```php
<?php

namespace App\Modules\Contacts\Infrastructure\Persistence;

use App\Modules\Contacts\Application\DTOs\CreateContactDTO;
use App\Modules\Contacts\Domain\Interfaces\ContactRepositoryInterface;
use App\Modules\Contacts\Infrastructure\Database\Models\Contact;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ContactRepository implements ContactRepositoryInterface
{
    public function create(CreateContactDTO $dto): Contact
    {
        return Contact::create((array) $dto);
    }

    public function getAll(string $tenantId, int $perPage = 15): LengthAwarePaginator
    {
        return Contact::where('tenant_id', $tenantId)
            ->orderBy('name_ar')
            ->paginate($perPage);
    }

    public function findById(string $tenantId, string $id): Contact
    {
        return Contact::where('tenant_id', $tenantId)->findOrFail($id);
    }

    public function update(Contact $contact, array $data): Contact
    {
        $contact->update($data);
        return $contact->fresh();
    }

    public function delete(Contact $contact): void
    {
        $contact->delete();
    }
}
```

### Service Provider binding (Infrastructure layer)

```php
<?php

namespace App\Modules\Contacts\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Contacts\Domain\Interfaces\ContactRepositoryInterface;
use App\Modules\Contacts\Infrastructure\Persistence\ContactRepository;

class ContactServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(ContactRepositoryInterface::class, ContactRepository::class);
    }

    public function boot(): void
    {
        $this->loadRoutesFrom(__DIR__ . '/../../../Presentation/Routes/api.php');
        $this->registerTranslations();
    }

    protected function registerTranslations(): void
    {
        $this->loadTranslationsFrom(
            __DIR__ . '/../../Presentation/Resources/Lang',
            'contacts'
        );
    }
}
```

---

## 8. API Response Structure

**All responses must use this exact structure.**

```php
<?php
// app/Modules/Core/Infrastructure/Helpers/ApiResponse.php

namespace App\Modules\Core\Infrastructure\Helpers;

use Illuminate\Http\JsonResponse;

class ApiResponse
{
    public static function success(mixed $data = null, string $message = '', int $statusCode = 200): JsonResponse
    {
        return response()->json([
            'status'  => true,
            'message' => $message,
            'data'    => $data,
        ], $statusCode);
    }

    public static function error(string $message, int $statusCode = 400, mixed $errors = null): JsonResponse
    {
        return response()->json([
            'status'  => false,
            'message' => $message,
            'errors'  => $errors,
        ], $statusCode);
    }

    public static function paginated(mixed $data, ?string $message = null, int $statusCode = 200): JsonResponse
    {
        return response()->json([
            'status'  => true,
            'message' => $message ?? __('messages.success'),
            'data'    => $data->items(),
            'meta'    => PaginationMeta::getMeta($data),
        ], $statusCode);
    }
}
```

```php
<?php
// app/Modules/Core/Infrastructure/Helpers/PaginationMeta.php

namespace App\Modules\Core\Infrastructure\Helpers;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Contracts\Pagination\Paginator;
use Illuminate\Pagination\CursorPaginator;

class PaginationMeta
{
    public static function getMeta(mixed $paginator): array
    {
        if ($paginator instanceof CursorPaginator) {
            return [
                'type'      => 'cursor',
                'next_page' => $paginator->nextCursor()?->encode(),
                'prev_page' => $paginator->previousCursor()?->encode(),
                'per_page'  => $paginator->perPage(),
                'has_more'  => $paginator->hasMorePages(),
            ];
        }

        if ($paginator instanceof LengthAwarePaginator) {
            return [
                'type'         => 'length_aware',
                'current_page' => $paginator->currentPage(),
                'last_page'    => $paginator->lastPage(),
                'per_page'     => $paginator->perPage(),
                'total'        => $paginator->total(),
                'from'         => $paginator->firstItem(),
                'to'           => $paginator->lastItem(),
                'has_more'     => $paginator->hasMorePages(),
            ];
        }

        if ($paginator instanceof Paginator) {
            return [
                'type'         => 'simple',
                'current_page' => $paginator->currentPage(),
                'per_page'     => $paginator->perPage(),
                'has_more'     => $paginator->hasMorePages(),
            ];
        }

        return [];
    }
}
```

**Success response shape:**
```json
{
  "status": true,
  "message": "Contact created successfully",
  "data": { ... }
}
```

**Error response shape:**
```json
{
  "status": false,
  "message": "Validation failed",
  "errors": {
    "name_ar": ["The Arabic name field is required."]
  }
}
```

**Paginated response shape:**
```json
{
  "status": true,
  "message": "Success",
  "data": [ ... ],
  "meta": {
    "type": "length_aware",
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 73,
    "from": 1,
    "to": 15,
    "has_more": true
  }
}
```

---

## 9. Migration Rules

### Tenant migrations → `database/migrations/tenant/`
### Central migrations → `database/migrations/central/`
### Primary keys are `CHAR(36)` UUID via Laravel's `uuid()` helper

```php
// Tenant migration template
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('contacts', function (Blueprint $table) {
            // Primary key — always first
            $table->uuid('contact_id')->primary();

            // tenant_id — always second column on every tenant table
            $table->uuid('tenant_id')->index();

            $table->string('name_ar', 150);
            $table->string('name_en', 150);
            $table->tinyInteger('type')->default(1); // 1=customer 2=supplier 3=both
            $table->string('phone', 30)->nullable();
            $table->string('email', 150)->nullable();
            $table->string('tax_number', 50)->nullable();
            $table->decimal('credit_limit', 15, 4)->default(0);
            $table->boolean('is_active')->default(true);

            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'type']);
            $table->index(['tenant_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('contacts');
    }
};
```

### Financial columns rule
All monetary / quantity columns **must** use `decimal(15,4)`.
**Never** use `double`, `float`, or `decimal(8,2)` for financial data.

### Migration Rules Checklist
- [ ] Primary key: `uuid('{table_singular}_id')->primary()`
- [ ] `tenant_id uuid()->index()` is the **second** column on every tenant table
- [ ] Bilingual text: both `name_ar` and `name_en` present
- [ ] Financial decimals: `decimal(15,4)` — never float or double
- [ ] `->nullable()` only when the field is truly optional
- [ ] Status columns: `tinyInteger('status')->default(1)` with PHPDoc comment
- [ ] Soft-deletable records: `$table->softDeletes()`
- [ ] `$table->index(...)` for every column used in WHERE or ORDER BY
- [ ] `$table->unique(...)` for unique constraint pairs
- [ ] `$table->timestamps()` always included

---

## 10. Tenant Scoping Middleware

Since all tenants share one database, `tenant_id` is injected from the authenticated JWT user on every request. A middleware resolves this automatically for all tenant routes.

```php
// app/Http/Middleware/ScopeTenant.php
// Applied to all /api/v1/{module}/... routes

class ScopeTenant
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = auth('api')->user();

        if (!$user || !$user->tenant_id) {
            return ApiResponse::error('Tenant not resolved', 401);
        }

        // Make tenant_id available to all downstream layers
        app()->instance('tenant_id', $user->tenant_id);

        return $next($request);
    }
}
```

```php
// Always scope queries explicitly in repositories:
Contact::where('tenant_id', app('tenant_id'))->...

// OR inject tenant_id through DTOs passed from the controller
```

### Route groups
```php
// routes/api.php

// Central — platform admin
Route::middleware(['api', 'auth:platform'])
    ->prefix('api/v1/central')
    ->group(base_path('routes/central.php'));

// Tenant auth (no scoping needed)
Route::middleware(['api'])
    ->prefix('api/v1/auth')
    ->group(base_path('routes/auth.php'));

// Tenant modules
Route::middleware(['api', 'auth:api', 'scope.tenant'])
    ->prefix('api/v1')
    ->group(base_path('routes/tenant.php'));
```

### What you must NOT do
```php
// ❌ WRONG — never query a tenant table without tenant_id scope
$contacts = Contact::all();

// ❌ WRONG — never hardcode a tenant_id in business logic
$contacts = Contact::where('tenant_id', 'some-hardcoded-uuid')->get();

// ❌ WRONG — never skip tenant_id on tenant table migrations
$table->uuid('contact_id')->primary();
$table->string('name_ar'); // missing tenant_id as second column
```

```php
// ✅ CORRECT — always scope with tenant_id from app container or DTO
$contacts = Contact::where('tenant_id', app('tenant_id'))->paginate(15);

// ✅ CORRECT — for background jobs, pass tenant_id explicitly
class GenerateSalesReportJob implements ShouldQueue
{
    public function __construct(
        private string $tenantId,
        private string $periodStart,
        private string $periodEnd,
    ) {}

    public function handle(): void
    {
        app()->instance('tenant_id', $this->tenantId);
        // All repository calls below are now tenant-scoped
    }
}
```

---

## 11. Roles & Permissions

Using `spatie/laravel-permission` **inside each tenant's scoped tables** (`roles`, `permissions`, `role_user`, etc. — all with `tenant_id`).

### Configuration override (required)
```php
// config/permission.php
'column_names' => [
    'role_morph_key'  => 'model_id',
    'model_morph_key' => 'model_id',
],
'teams' => false,
```

### Permission naming convention
```
{resource}.{action}

Examples:
  contact.view       contact.create     contact.update     contact.delete
  product.view       product.create     product.update     product.delete
  inventory.view     inventory.adjust   inventory.transfer
  sale.view          sale.create        sale.delete        sale.return
  purchase.view      purchase.create    purchase.delete    purchase.return
  payment.view       payment.create
  finance.view       finance.manage
  expense.view       expense.create
  hr.view            employees.manage   payroll.manage
  pos.access
  report.view
  settings.manage
```

### Default Tenant Roles (seeded on tenant provisioning)

| Role | Guard | Typical Permissions |
|------|-------|---------------------|
| `admin` | api | All permissions |
| `manager` | api | contacts.*, products.*, inventory.*, sales.*, purchasing.*, payments.*, expenses.*, reports.view |
| `sales` | api | contacts.view, products.view, sales.*, payments.* |
| `purchaser` | api | contacts.view, products.view, purchasing.*, payments.* |
| `accountant` | api | finance.*, payments.*, expenses.*, reports.view |
| `cashier` | api | pos.access, payments.*, contacts.view |
| `hr` | api | hr.*, employees.*, payroll.* |
| `viewer` | api | *.view only |

### Usage
```php
// Via middleware on routes
Route::middleware(['permission:contact.create'])->post('/contacts', ...);

// Manual check in service
if (!auth()->user()->can('sale.delete')) {
    return ApiResponse::error('Unauthorized', 403);
}
```

---

## 12. Form Request Rules

```php
<?php

namespace App\Modules\Contacts\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreContactRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('contact.create');
    }

    public function rules(): array
    {
        return [
            'name_ar'      => ['required', 'string', 'max:150'],
            'name_en'      => ['required', 'string', 'max:150'],
            'type'         => ['required', 'integer', 'in:1,2,3'],
            'phone'        => ['nullable', 'string', 'max:30'],
            'email'        => ['nullable', 'email', 'max:150'],
            'tax_number'   => ['nullable', 'string', 'max:50'],
            'credit_limit' => ['sometimes', 'numeric', 'min:0'],
            'is_active'    => ['sometimes', 'boolean'],
        ];
    }
}
```

---

## 13. Resource Rules

```php
<?php

namespace App\Modules\Contacts\Presentation\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ContactResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'           => $this->contact_id,   // always expose as 'id' in API
            'name_ar'      => $this->name_ar,
            'name_en'      => $this->name_en,
            'type'         => $this->type,
            'phone'        => $this->phone,
            'email'        => $this->email,
            'tax_number'   => $this->tax_number,
            'credit_limit' => $this->credit_limit,
            'is_active'    => $this->is_active,
            'created_at'   => $this->created_at?->diffForHumans(),
            'updated_at'   => $this->updated_at?->diffForHumans(),

            // Conditional relationships — only include when loaded
            'addresses'    => ContactAddressResource::collection($this->whenLoaded('addresses')),
        ];
    }
}
```

### Resource Rules Checklist
- [ ] Always map `{model}_id` → `id` in API output
- [ ] Always format datetimes via `->diffForHumans()` or Carbon
- [ ] Always use `$this->whenLoaded('relation')` — never unconditional eager loads
- [ ] Never expose `password`, `remember_token`, or encrypted fields
- [ ] Never expose `tenant_id` in public API responses
- [ ] Expose `deleted_at` only on admin-facing resources

---

## 14. Horizon & Queue Rules

```php
// Queues used in this project
const QUEUES = [
    'default',        // general async tasks          — 60s timeout
    'notifications',  // email, SMS, FCM fan-out      — 120s timeout
    'reports',        // heavy report generation      — 300s timeout
    'imports',        // bulk CSV/Excel imports        — 300s timeout
    'exports',        // PDF/Excel generation          — 300s timeout
    'billing',        // invoice generation, webhooks  — 120s timeout
];

// All jobs must:
// 1. implement ShouldQueue
// 2. use the correct queue
// 3. pass tenant_id explicitly and set it in handle()
// 4. define $tries and $timeout

class GenerateSalesReportJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries   = 3;
    public int $timeout = 300;

    public function __construct(
        private string $tenantId,
        private string $periodStart,
        private string $periodEnd,
    ) {}

    public function handle(): void
    {
        app()->instance('tenant_id', $this->tenantId);

        // ... report logic scoped to tenant_id
    }
}
```

---

## 15. Notifications Rules

```php
// Supported channels
enum NotificationChannel: int
{
    case InApp  = 1;
    case Email  = 2;
    case Sms    = 3;
    case Push   = 4;   // FCM via fcm_token on users table
}

// All notification classes extend this base
abstract class BaseNotification extends Notification
{
    abstract public function toDatabase(mixed $notifiable): array;
    abstract public function toMail(mixed $notifiable): MailMessage;
    // override toFcm() and toVonage() as needed
}
```

---

## 16. Media Files Rules

There is **one unified table** for all files and media: `media_files`.
**Never create a separate attachments/images column or table in any module.**

```php
// Attach a file to any model:
MediaFile::create([
    'tenant_id'        => app('tenant_id'),
    'owner_type'       => 'purchase_order',
    'owner_id'         => $order->purchase_order_id,
    'uploaded_by'      => auth()->id(),
    'media_category'   => MediaCategory::Attachment->value,
    'storage_provider' => StorageProvider::S3->value,
    'storage_path'     => $path,
    'original_name'    => $file->getClientOriginalName(),
    'mime_type'        => $file->getMimeType(),
    'size_bytes'       => $file->getSize(),
    'is_public'        => false,
]);

// Retrieve all files for a model:
$files = MediaFile::where('tenant_id', app('tenant_id'))
    ->where('owner_type', 'purchase_order')
    ->where('owner_id', $order->purchase_order_id)
    ->get();
```

**owner_type values:**
`contact`, `product`, `purchase_order`, `sales_invoice`, `payment`,
`expense`, `employee`, `payslip`, `journal_entry`, `stock_adjustment`,
`user`, `tenant`

---

## 17. Settings Module Rules

Tenant settings use a key-value store scoped to `tenant_id` (and optionally `business_location_id`).

```php
// Get a setting
$value = Setting::where('tenant_id', app('tenant_id'))
    ->where('key', 'sales.invoice_prefix')
    ->value('value');

// Set a setting
Setting::updateOrCreate(
    ['tenant_id' => app('tenant_id'), 'key' => 'sales.invoice_prefix'],
    ['value' => 'INV-']
);
```

**Key naming convention:** `{module}.{setting_name}` — e.g.:
- `sales.invoice_prefix`
- `purchasing.po_prefix`
- `inventory.allow_negative_stock`
- `finance.default_currency`
- `hr.payroll_day`

---

## 18. ActivityLog Module Rules

The `ActivityLog` module is a **P0** dependency. Every module that mutates data must log the activity.

```php
// Usage from any Use Case
$this->logActivity->execute(
    event:      'contact.created',
    entityType: 'contact',
    entityId:   $contact->contact_id,
    tenantId:   app('tenant_id'),
    userId:     auth()->id(),
    payload:    (array) $dto,
);
```

The `ActivityLog` module writes to `tenant_audit_logs` (tenant-scoped) and optionally to `audit_logs` (central) for billing/provisioning events.

---

## 19. What Cursor AI Must Never Do

- ❌ Never use `auto-increment` primary keys — always UUID `CHAR(36)`
- ❌ Never create a tenant table without `tenant_id` as the **second** column
- ❌ Never query a tenant table without scoping by `tenant_id`
- ❌ Never put logic in controllers — controllers call Use Cases only
- ❌ Never put Eloquent queries in Use Cases — Use Cases call Repositories via interface
- ❌ Never put framework code in the Domain layer — Domain is pure PHP
- ❌ Never instantiate Use Cases or Repositories with `new` — always inject via constructor
- ❌ Never return raw `$model->toArray()` — always use a Resource
- ❌ Never use `$request->validate()` inline — always use a Form Request class
- ❌ Never use `double` or `float` for monetary columns — always `decimal(15,4)`
- ❌ Never create a separate table for file attachments — use `media_files`
- ❌ Never skip `->whenLoaded()` on resource relationships
- ❌ Never expose `tenant_id` in public API responses
- ❌ Never expose `_id` suffixed primary keys in API responses — map to `id`
- ❌ Never skip bilingual fields — every user-visible name needs `_ar` and `_en`
- ❌ Never skip `softDeletes()` on models that represent real-world entities
- ❌ Never place a model outside its module's `Infrastructure/Database/Models/` folder
- ❌ Never access `Request` inside a Use Case
- ❌ Never return Eloquent Models from a Use Case — return DTO or plain array
- ❌ Never couple a Use Case to Laravel (`Collection`, `Response`, etc.)
- ❌ Never put validation inside a Use Case — validation belongs in FormRequest only
- ❌ Never write migrations without adding required indexes
- ❌ Never skip ActivityLog calls on data-mutating Use Cases
- ❌ Never use `stancl/tenancy` — this project uses single-DB tenancy with `tenant_id` scoping

---

## 20. Module File Reference

| Module | Rules File | DB Tier |
|--------|-----------|---------|
| Core / Shared | `.cursor/rules/core.md` | Both |
| Auth & JWT | `.cursor/rules/auth.md` | Tenant |
| Tenant Scoping | `.cursor/rules/tenancy.md` | Both |
| Tenants / Platform | `.cursor/rules/tenants.md` | Central |
| Platform Users | `.cursor/rules/platform-users.md` | Central |
| Plans & Billing | `.cursor/rules/billing.md` | Central |
| Users & Roles | `.cursor/rules/users.md` | Tenant |
| Contacts (CRM) | `.cursor/rules/contacts.md` | Tenant |
| Products | `.cursor/rules/products.md` | Tenant |
| Inventory | `.cursor/rules/inventory.md` | Tenant |
| Sales | `.cursor/rules/sales.md` | Tenant |
| Purchasing | `.cursor/rules/purchasing.md` | Tenant |
| Finance | `.cursor/rules/finance.md` | Tenant |
| Payments | `.cursor/rules/payments.md` | Tenant |
| Expenses | `.cursor/rules/expenses.md` | Tenant |
| HR & Payroll | `.cursor/rules/hr.md` | Tenant |
| Reports | `.cursor/rules/reports.md` | Tenant |
| Settings | `.cursor/rules/settings.md` | Tenant |
| Notifications | `.cursor/rules/notifications.md` | Tenant |
| ActivityLog | `.cursor/rules/activity-log.md` | Tenant |
| Media Files | `.cursor/rules/media.md` | Tenant |

---

## 21. Phased Build Order

| Phase | Modules | Priority |
|-------|---------|----------|
| **P0 — Foundation** | Core, ActivityLog, Tenants (central), tenant-scoping middleware, JWT guards | Week 1 |
| **P1 — Identity & Access** | PlatformUsers, Auth, Users, Roles, Settings | Weeks 2–3 |
| **P2 — CRM & Catalog** | Contacts, Products, bulk import jobs | Weeks 4–5 |
| **P3 — Inventory** | Inventory (warehouses, stock movements, adjustments, transfers) | Week 6 |
| **P4 — Transactions** | Sales, Purchasing, Payments, reference number generation | Weeks 7–8 |
| **P5 — Finance & Expenses** | Finance (chart of accounts, journal entries), Expenses | Weeks 9–10 |
| **P6 — HR & Payroll** | HR, Payroll, attendance, payslips | Weeks 11–12 |
| **P7 — Billing, Notifications & Reports** | Billing (Cashier), Notifications, Reports (async via Horizon) | Weeks 13–14 |
| **P8 — Polish & Scale** | Central dashboard, indexing, caching, PDF/Excel exports, OpenAPI docs | Week 15+ |

---

## 22. Project Guides

| Guide | File | Purpose |
|-------|------|---------|
| How to work on this project | `CONTRIBUTING.md` | Task checklist, code quality gates, all file templates, module build order |
| Zero-to-running setup | `PROJECT_BOOTSTRAP.md` | Package install, env config, DB setup, Horizon queues, first tenant creation |

---

*Last updated: May 2026 — Rakeeza ERP v1.0 (Commercial/Trading)*