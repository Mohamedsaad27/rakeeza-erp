# 🏗️ Rakeeza ERP — Full System Plan
> Laravel 13 · Module-Based Clean Architecture · Single DB Multi-Tenancy · MySQL 8+

---

## Table of Contents

1. [Current DB Audit & Critical Issues](#1-current-db-audit--critical-issues)
2. [Multi-Tenancy Strategy](#2-multi-tenancy-strategy)
3. [Enhanced Database Schema — All Modules](#3-enhanced-database-schema--all-modules)
4. [Module Feature Plan](#4-module-feature-plan)
5. [Package & Dependency Plan](#5-package--dependency-plan)
6. [Module Architecture Structure](#6-module-architecture-structure)
7. [Queue & Job Strategy (Horizon)](#7-queue--job-strategy-horizon)
8. [API & Auth Strategy (Passport)](#8-api--auth-strategy-passport)
9. [Roles & Permissions Strategy (Spatie)](#9-roles--permissions-strategy-spatie)
10. [Reporting & Analytics Strategy](#10-reporting--analytics-strategy)
11. [Development Phases Roadmap](#11-development-phases-roadmap)

---

## 1. Current DB Audit & Critical Issues

### ✅ What Already Exists (Good Foundation)
| Table | Purpose |
|---|---|
| `users`, `roles`, `permissions`, `role_user`, `permission_user`, `permission_role` | Auth & RBAC (Laratrust-style) |
| `contacts` | Unified customers + suppliers (type enum) |
| `products`, `brands`, `categories`, `units` | Product catalog |
| `product_unit_details`, `product_branch_details` | Multi-unit + per-branch stock |
| `transactions` + `transactions_sell_lines` + `transactions_purchase_lines` | Core sales & purchases |
| `payments`, `payment_transactions` | Payment ledger |
| `accounts` | Cash/credit accounts |
| `branchs`, `governorates`, `cities` | Location hierarchy |
| `activity_log` | Audit trail |
| `media` | Spatie Medialibrary |
| `expenses`, `expense_categories` | Basic expense tracking |

### ❌ Critical Issues to Fix

#### 1. No `tenant_id` — The #1 Problem
Every table is missing `tenant_id`. This is the foundation of multi-tenancy.
**Every single table must have `tenant_id BIGINT UNSIGNED NOT NULL` as the second column.**

#### 2. Missing Tables for Planned Modules
| Missing Area | Impact |
|---|---|
| No `tenants` table | Can't run SaaS at all |
| No `journal_entries` / `chart_of_accounts` | Finance module is incomplete |
| No `warehouses` / `stock_movements` | Inventory is basic/unreliable |
| No HR tables (`employees`, `attendance`, `payroll`) | HR module missing entirely |
| No `crm_*` tables | CRM missing entirely |
| No `tax_*` tables | Compliance risk |
| No `subscription_plans` | Cashier/billing can't work |

#### 3. Schema Quality Issues
- `branchs` → should be `branches` (typo in every foreign key)
- `balance` on `accounts` and `contacts` uses `double(8,2)` — **must use `decimal(15,4)`** for financial precision
- `activity_log.proccess_type` is a narrow enum — should be a `varchar` with a separate lookup table
- `settings` and `site_settings` are two tables doing the same job — merge into `tenant_settings`
- `reference_counts` is a fragile sequence counter — replace with proper auto-increment + prefix logic
- `personal_access_tokens` (Sanctum) should be removed — you're using Passport (OAuth2 tokens)
- `images` table is redundant alongside `media` (Spatie Medialibrary) — remove `images`
- `contacts.password` and `contacts.remember_token` — mixing contact entity with auth is an anti-pattern

---

## 2. Multi-Tenancy Strategy

### Architecture: Single Database, `tenant_id` Scoping

```
SaaS Platform (Rakeeza)
├── tenants (companies/businesses)
│   ├── tenant_id = 1 → "Al-Nour Trading"
│   ├── tenant_id = 2 → "Cairo Store"
│   └── tenant_id = 3 → "Delta Supplies"
└── All data tables contain tenant_id
```

### `tenants` Table (New — Core Table)
```sql
CREATE TABLE tenants (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid          CHAR(36) NOT NULL UNIQUE,              -- used in subdomains/URLs
  name          VARCHAR(255) NOT NULL,
  slug          VARCHAR(100) NOT NULL UNIQUE,          -- e.g. "al-nour" → al-nour.rakeeza.com
  email         VARCHAR(255) NOT NULL UNIQUE,          -- owner email
  phone         VARCHAR(50),
  logo          VARCHAR(500),
  status        ENUM('active','suspended','cancelled') DEFAULT 'active',
  trial_ends_at TIMESTAMP NULL,
  plan_id       BIGINT UNSIGNED,                       -- FK to subscription_plans
  settings      JSON,                                  -- tenant-level overrides
  created_at    TIMESTAMP,
  updated_at    TIMESTAMP,
  deleted_at    TIMESTAMP NULL
);
```

### Global Scope Implementation
```php
// app/Http/Middleware/SetTenantScope.php
class SetTenantScope {
    public function handle($request, $next) {
        $tenant = Tenant::where('slug', $request->subdomain())->firstOrFail();
        app()->instance('currentTenant', $tenant);
        return $next($request);
    }
}

// app/Models/Concerns/BelongsToTenant.php (Trait)
trait BelongsToTenant {
    protected static function bootBelongsToTenant() {
        static::addGlobalScope('tenant', function($query) {
            $query->where('tenant_id', app('currentTenant')->id);
        });
        static::creating(function($model) {
            $model->tenant_id = app('currentTenant')->id;
        });
    }
}
```

### `tenant_id` Indexing Rule
Every table that has `tenant_id` must have a **composite index**:
```sql
-- Example: Index on transactions
INDEX idx_tenant_type (tenant_id, type),
INDEX idx_tenant_date (tenant_id, transaction_date),
INDEX idx_tenant_contact (tenant_id, contact_id)
```

---

## 3. Enhanced Database Schema — All Modules

### 3.1 Core / Tenancy

```sql
-- tenants (described above)

CREATE TABLE subscription_plans (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,           -- 'Starter', 'Pro', 'Enterprise'
  stripe_plan VARCHAR(255),                    -- Cashier plan ID
  price       DECIMAL(10,2) NOT NULL,
  billing_cycle ENUM('monthly','yearly') DEFAULT 'monthly',
  max_branches INT DEFAULT 1,
  max_users    INT DEFAULT 5,
  features     JSON,                           -- feature flags per plan
  is_active    TINYINT(1) DEFAULT 1,
  created_at  TIMESTAMP,
  updated_at  TIMESTAMP
);

CREATE TABLE tenant_settings (
  id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id                   BIGINT UNSIGNED NOT NULL UNIQUE,
  logo                        VARCHAR(500),
  site_name                   VARCHAR(255),
  currency                    VARCHAR(10) DEFAULT 'EGP',
  currency_symbol             VARCHAR(10) DEFAULT 'ج.م',
  date_format                 VARCHAR(50) DEFAULT 'Y-m-d',
  time_zone                   VARCHAR(100) DEFAULT 'Africa/Cairo',
  language                    VARCHAR(10) DEFAULT 'ar',
  tax_number                  VARCHAR(100),
  tax_rate                    DECIMAL(5,2) DEFAULT 0.00,
  fiscal_year_start           DATE,
  allow_unit_price_update     TINYINT(1) DEFAULT 0,
  prevent_sell_below_cost     TINYINT(1) DEFAULT 1,
  default_credit_limit        DECIMAL(15,4) DEFAULT 0,
  thermal_printing            TINYINT(1) DEFAULT 0,
  classic_printing            TINYINT(1) DEFAULT 1,
  invoice_footer_note         TEXT,
  display_options             JSON,            -- all the display_* boolean columns in JSON
  created_at                  TIMESTAMP,
  updated_at                  TIMESTAMP,
  FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);
```

### 3.2 Auth & Users (Enhanced)

```sql
-- Rename `branchs` → `branches` and add tenant_id
ALTER TABLE branchs RENAME TO branches;

CREATE TABLE branches (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id         BIGINT UNSIGNED NOT NULL,
  name              VARCHAR(255) NOT NULL,
  code              VARCHAR(50),
  address           TEXT,
  phone             VARCHAR(50),
  governorate_id    BIGINT UNSIGNED,
  city_id           BIGINT UNSIGNED,
  cash_account_id   BIGINT UNSIGNED,
  credit_account_id BIGINT UNSIGNED,
  is_active         TINYINT(1) DEFAULT 1,
  is_main           TINYINT(1) DEFAULT 0,
  created_at        TIMESTAMP,
  updated_at        TIMESTAMP,
  deleted_at        TIMESTAMP NULL,
  INDEX idx_tenant (tenant_id)
);

-- Enhanced users table
ALTER TABLE users
  ADD COLUMN tenant_id    BIGINT UNSIGNED NOT NULL AFTER id,
  ADD COLUMN phone        VARCHAR(50) AFTER email,
  ADD COLUMN avatar       VARCHAR(500),
  ADD COLUMN is_active    TINYINT(1) DEFAULT 1,
  ADD COLUMN last_login_at TIMESTAMP NULL,
  ADD INDEX idx_tenant (tenant_id);

-- Passport OAuth tables (added by Laravel Passport migration)
-- oauth_clients, oauth_access_tokens, oauth_refresh_tokens, etc.
-- No personal_access_tokens needed (that is Sanctum)
```

### 3.3 Roles & Permissions (Spatie Compatible)

```sql
-- Spatie permission tables (scoped per tenant)
-- The standard spatie tables need team_id enabled for multi-tenancy

CREATE TABLE roles (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id   BIGINT UNSIGNED NOT NULL,         -- scope per tenant
  name        VARCHAR(255) NOT NULL,
  guard_name  VARCHAR(255) NOT NULL DEFAULT 'api',
  display_name VARCHAR(255),
  description  VARCHAR(500),
  is_system    TINYINT(1) DEFAULT 0,            -- system roles cannot be deleted
  created_at  TIMESTAMP,
  updated_at  TIMESTAMP,
  UNIQUE KEY unique_name_tenant (tenant_id, name, guard_name),
  INDEX idx_tenant (tenant_id)
);

CREATE TABLE permissions (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,            -- 'sales.create', 'inventory.view'
  guard_name  VARCHAR(255) NOT NULL DEFAULT 'api',
  module      VARCHAR(100),                     -- 'sales', 'inventory', 'hr'
  display_name VARCHAR(255),
  description  VARCHAR(500),
  created_at  TIMESTAMP,
  updated_at  TIMESTAMP,
  UNIQUE KEY unique_name_guard (name, guard_name)
);
-- model_has_roles, model_has_permissions, role_has_permissions (standard spatie tables)
```

### 3.4 Contacts (Customers & Suppliers — Enhanced)

```sql
-- Remove password/remember_token from contacts (auth anti-pattern)
-- Add proper CRM fields

ALTER TABLE contacts
  ADD COLUMN tenant_id        BIGINT UNSIGNED NOT NULL AFTER id,
  ADD COLUMN tax_number       VARCHAR(100),
  ADD COLUMN national_id      VARCHAR(50),
  ADD COLUMN contact_person   VARCHAR(255),     -- for suppliers: contact person name
  ADD COLUMN website          VARCHAR(255),
  ADD COLUMN notes            TEXT,
  ADD COLUMN tags             JSON,             -- ['vip','wholesale']
  ADD COLUMN assigned_to      BIGINT UNSIGNED,  -- FK users (for CRM)
  DROP COLUMN password,
  DROP COLUMN remember_token,
  DROP COLUMN government,                       -- replaced by governorate_id FK
  DROP COLUMN city,                             -- replaced by city_id FK
  ADD INDEX idx_tenant_type (tenant_id, type),
  ADD INDEX idx_tenant_code (tenant_id, contact_code);

-- Customer portal (optional - for customers to login to track orders)
CREATE TABLE customer_portal_users (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id    BIGINT UNSIGNED NOT NULL,
  contact_id   BIGINT UNSIGNED NOT NULL,
  email        VARCHAR(255) NOT NULL,
  password     VARCHAR(255) NOT NULL,
  verified_at  TIMESTAMP NULL,
  remember_token VARCHAR(100),
  created_at   TIMESTAMP,
  updated_at   TIMESTAMP,
  FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
);
```

### 3.5 Products & Inventory (Enhanced)

```sql
ALTER TABLE products
  ADD COLUMN tenant_id        BIGINT UNSIGNED NOT NULL AFTER id,
  ADD COLUMN barcode          VARCHAR(255),
  ADD COLUMN type             ENUM('standard','variable','service','combo') DEFAULT 'standard',
  ADD COLUMN tax_rate         DECIMAL(5,2) DEFAULT 0,
  ADD COLUMN is_serialized    TINYINT(1) DEFAULT 0,   -- track by serial number
  ADD COLUMN has_expiry       TINYINT(1) DEFAULT 0,   -- track expiry dates
  ADD COLUMN image_path       VARCHAR(500),
  ADD COLUMN weight           DECIMAL(10,3),
  ADD COLUMN notes            TEXT,
  ADD INDEX idx_tenant (tenant_id),
  ADD INDEX idx_tenant_sku (tenant_id, sku),
  ADD INDEX idx_tenant_barcode (tenant_id, barcode);

-- Warehouses (more flexible than branches for inventory)
CREATE TABLE warehouses (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id   BIGINT UNSIGNED NOT NULL,
  branch_id   BIGINT UNSIGNED,
  name        VARCHAR(255) NOT NULL,
  code        VARCHAR(50),
  address     TEXT,
  is_active   TINYINT(1) DEFAULT 1,
  is_default  TINYINT(1) DEFAULT 0,
  created_at  TIMESTAMP,
  updated_at  TIMESTAMP,
  deleted_at  TIMESTAMP NULL,
  INDEX idx_tenant (tenant_id)
);

-- Stock per warehouse (replaces product_branch_details)
CREATE TABLE stock_levels (
  id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id      BIGINT UNSIGNED NOT NULL,
  warehouse_id   BIGINT UNSIGNED NOT NULL,
  product_id     BIGINT UNSIGNED NOT NULL,
  unit_id        BIGINT UNSIGNED NOT NULL,
  qty_available  DECIMAL(15,4) NOT NULL DEFAULT 0,
  qty_reserved   DECIMAL(15,4) NOT NULL DEFAULT 0,   -- reserved by pending orders
  qty_on_order   DECIMAL(15,4) NOT NULL DEFAULT 0,   -- in open POs
  updated_at     TIMESTAMP,
  UNIQUE KEY unique_stock (tenant_id, warehouse_id, product_id, unit_id),
  INDEX idx_tenant_product (tenant_id, product_id)
);

-- Every stock movement is recorded (full audit trail)
CREATE TABLE stock_movements (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id       BIGINT UNSIGNED NOT NULL,
  warehouse_id    BIGINT UNSIGNED NOT NULL,
  product_id      BIGINT UNSIGNED NOT NULL,
  unit_id         BIGINT UNSIGNED NOT NULL,
  transaction_id  BIGINT UNSIGNED,                   -- FK transactions
  movement_type   ENUM('purchase','sale','sale_return','purchase_return',
                        'transfer_in','transfer_out','adjustment',
                        'opening_stock','spoilage','production') NOT NULL,
  quantity        DECIMAL(15,4) NOT NULL,            -- positive = in, negative = out
  unit_cost       DECIMAL(15,4),
  reference_no    VARCHAR(100),
  note            TEXT,
  created_by      BIGINT UNSIGNED,
  created_at      TIMESTAMP,
  INDEX idx_tenant_product (tenant_id, product_id),
  INDEX idx_tenant_date (tenant_id, created_at),
  INDEX idx_transaction (transaction_id)
);

-- Batch/Lot tracking (for expiry, serial numbers)
CREATE TABLE product_batches (
  id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id      BIGINT UNSIGNED NOT NULL,
  product_id     BIGINT UNSIGNED NOT NULL,
  warehouse_id   BIGINT UNSIGNED NOT NULL,
  batch_number   VARCHAR(100),
  serial_number  VARCHAR(100),
  expiry_date    DATE,
  quantity       DECIMAL(15,4) DEFAULT 0,
  cost_price     DECIMAL(15,4),
  created_at     TIMESTAMP,
  updated_at     TIMESTAMP,
  INDEX idx_tenant_product (tenant_id, product_id)
);

-- Stock adjustments (formal process)
CREATE TABLE stock_adjustments (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id       BIGINT UNSIGNED NOT NULL,
  warehouse_id    BIGINT UNSIGNED NOT NULL,
  ref_no          VARCHAR(100),
  reason          VARCHAR(500),
  status          ENUM('draft','approved','rejected') DEFAULT 'draft',
  approved_by     BIGINT UNSIGNED,
  approved_at     TIMESTAMP NULL,
  created_by      BIGINT UNSIGNED NOT NULL,
  created_at      TIMESTAMP,
  updated_at      TIMESTAMP,
  INDEX idx_tenant (tenant_id)
);

CREATE TABLE stock_adjustment_lines (
  id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  stock_adjustment_id BIGINT UNSIGNED NOT NULL,
  product_id          BIGINT UNSIGNED NOT NULL,
  unit_id             BIGINT UNSIGNED NOT NULL,
  qty_system          DECIMAL(15,4) NOT NULL,   -- what system says
  qty_actual          DECIMAL(15,4) NOT NULL,   -- what was counted
  difference          DECIMAL(15,4) GENERATED ALWAYS AS (qty_actual - qty_system) STORED,
  FOREIGN KEY (stock_adjustment_id) REFERENCES stock_adjustments(id) ON DELETE CASCADE
);
```

### 3.6 Finance & Accounting (New — Full Double-Entry)

```sql
-- Chart of Accounts
CREATE TABLE account_types (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,           -- 'Asset', 'Liability', 'Equity', 'Revenue', 'Expense'
  normal_balance ENUM('debit','credit') NOT NULL,
  created_at  TIMESTAMP
);

CREATE TABLE chart_of_accounts (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id       BIGINT UNSIGNED NOT NULL,
  parent_id       BIGINT UNSIGNED,
  account_type_id BIGINT UNSIGNED NOT NULL,
  code            VARCHAR(50) NOT NULL,         -- e.g., '1001', '4001'
  name            VARCHAR(255) NOT NULL,
  description     TEXT,
  currency        VARCHAR(10) DEFAULT 'EGP',
  is_system       TINYINT(1) DEFAULT 0,         -- system accounts cannot be deleted
  is_active       TINYINT(1) DEFAULT 1,
  created_at      TIMESTAMP,
  updated_at      TIMESTAMP,
  deleted_at      TIMESTAMP NULL,
  UNIQUE KEY unique_code_tenant (tenant_id, code),
  INDEX idx_tenant (tenant_id),
  FOREIGN KEY (account_type_id) REFERENCES account_types(id)
);

-- Journal Entries (double-entry bookkeeping)
CREATE TABLE journal_entries (
  id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id      BIGINT UNSIGNED NOT NULL,
  entry_number   VARCHAR(100),
  entry_date     DATE NOT NULL,
  reference_type VARCHAR(100),                  -- 'transaction', 'payment', 'expense'
  reference_id   BIGINT UNSIGNED,
  description    TEXT,
  is_posted      TINYINT(1) DEFAULT 0,
  posted_at      TIMESTAMP NULL,
  posted_by      BIGINT UNSIGNED,
  created_by     BIGINT UNSIGNED NOT NULL,
  created_at     TIMESTAMP,
  updated_at     TIMESTAMP,
  INDEX idx_tenant_date (tenant_id, entry_date),
  INDEX idx_reference (reference_type, reference_id)
);

CREATE TABLE journal_entry_lines (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  journal_entry_id BIGINT UNSIGNED NOT NULL,
  account_id       BIGINT UNSIGNED NOT NULL,    -- FK chart_of_accounts
  debit            DECIMAL(15,4) NOT NULL DEFAULT 0,
  credit           DECIMAL(15,4) NOT NULL DEFAULT 0,
  description      VARCHAR(500),
  FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON DELETE CASCADE,
  FOREIGN KEY (account_id) REFERENCES chart_of_accounts(id)
);

-- Tax configuration
CREATE TABLE taxes (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id   BIGINT UNSIGNED NOT NULL,
  name        VARCHAR(100) NOT NULL,            -- 'VAT 14%', 'Withholding 5%'
  rate        DECIMAL(5,2) NOT NULL,
  type        ENUM('percentage','fixed') DEFAULT 'percentage',
  is_active   TINYINT(1) DEFAULT 1,
  created_at  TIMESTAMP,
  updated_at  TIMESTAMP,
  INDEX idx_tenant (tenant_id)
);

-- Cost Centers
CREATE TABLE cost_centers (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id   BIGINT UNSIGNED NOT NULL,
  parent_id   BIGINT UNSIGNED,
  name        VARCHAR(255) NOT NULL,
  code        VARCHAR(50),
  is_active   TINYINT(1) DEFAULT 1,
  created_at  TIMESTAMP,
  updated_at  TIMESTAMP,
  INDEX idx_tenant (tenant_id)
);
```

### 3.7 Sales, Sales Returns & CRM (Enhanced)

```sql
-- Quotations (before converting to invoice)
CREATE TABLE quotations (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id       BIGINT UNSIGNED NOT NULL,
  branch_id       BIGINT UNSIGNED NOT NULL,
  contact_id      BIGINT UNSIGNED,
  ref_no          VARCHAR(100),
  quotation_date  DATE NOT NULL,
  expiry_date     DATE,
  status          ENUM('draft','sent','accepted','rejected','converted') DEFAULT 'draft',
  total           DECIMAL(15,4) DEFAULT 0,
  discount_type   ENUM('percentage','fixed') DEFAULT 'fixed',
  discount_value  DECIMAL(15,4) DEFAULT 0,
  tax_amount      DECIMAL(15,4) DEFAULT 0,
  final_price     DECIMAL(15,4) DEFAULT 0,
  notes           TEXT,
  converted_to_transaction_id BIGINT UNSIGNED,
  created_by      BIGINT UNSIGNED NOT NULL,
  created_at      TIMESTAMP,
  updated_at      TIMESTAMP,
  deleted_at      TIMESTAMP NULL,
  INDEX idx_tenant (tenant_id)
);

CREATE TABLE quotation_lines (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  quotation_id  BIGINT UNSIGNED NOT NULL,
  product_id    BIGINT UNSIGNED NOT NULL,
  unit_id       BIGINT UNSIGNED NOT NULL,
  quantity      DECIMAL(15,4) NOT NULL,
  unit_price    DECIMAL(15,4) NOT NULL,
  discount      DECIMAL(15,4) DEFAULT 0,
  tax_rate      DECIMAL(5,2) DEFAULT 0,
  total         DECIMAL(15,4) NOT NULL,
  FOREIGN KEY (quotation_id) REFERENCES quotations(id) ON DELETE CASCADE
);

-- CRM: Leads
CREATE TABLE crm_leads (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id     BIGINT UNSIGNED NOT NULL,
  contact_id    BIGINT UNSIGNED,              -- if converted to contact
  name          VARCHAR(255) NOT NULL,
  email         VARCHAR(255),
  phone         VARCHAR(50),
  company       VARCHAR(255),
  source        ENUM('website','referral','social','cold_call','exhibition','other'),
  status        ENUM('new','contacted','qualified','proposal','negotiation','won','lost') DEFAULT 'new',
  assigned_to   BIGINT UNSIGNED,
  estimated_value DECIMAL(15,4),
  expected_close_date DATE,
  notes         TEXT,
  created_by    BIGINT UNSIGNED NOT NULL,
  created_at    TIMESTAMP,
  updated_at    TIMESTAMP,
  deleted_at    TIMESTAMP NULL,
  INDEX idx_tenant_status (tenant_id, status),
  INDEX idx_tenant_assigned (tenant_id, assigned_to)
);

-- CRM: Activities (calls, meetings, emails)
CREATE TABLE crm_activities (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id     BIGINT UNSIGNED NOT NULL,
  lead_id       BIGINT UNSIGNED,
  contact_id    BIGINT UNSIGNED,
  type          ENUM('call','meeting','email','note','task') NOT NULL,
  subject       VARCHAR(255),
  description   TEXT,
  due_date      TIMESTAMP NULL,
  completed_at  TIMESTAMP NULL,
  outcome       VARCHAR(500),
  assigned_to   BIGINT UNSIGNED,
  created_by    BIGINT UNSIGNED NOT NULL,
  created_at    TIMESTAMP,
  updated_at    TIMESTAMP,
  INDEX idx_tenant (tenant_id)
);

-- Add tenant_id + tax fields to transactions
ALTER TABLE transactions
  ADD COLUMN tenant_id        BIGINT UNSIGNED NOT NULL AFTER id,
  ADD COLUMN warehouse_id     BIGINT UNSIGNED AFTER branch_id,
  ADD COLUMN quotation_id     BIGINT UNSIGNED,
  ADD COLUMN tax_amount       DECIMAL(15,4) DEFAULT 0,
  ADD COLUMN tax_id           BIGINT UNSIGNED,
  ADD COLUMN shipping_cost    DECIMAL(15,4) DEFAULT 0,
  ADD COLUMN notes            TEXT,
  ADD COLUMN currency         VARCHAR(10) DEFAULT 'EGP',
  ADD COLUMN exchange_rate    DECIMAL(10,6) DEFAULT 1.000000,
  ADD INDEX idx_tenant_type (tenant_id, type),
  ADD INDEX idx_tenant_date (tenant_id, transaction_date),
  ADD INDEX idx_tenant_status (tenant_id, status);
```

### 3.8 Purchasing & Purchase Returns (Enhanced)

```sql
-- Purchase Orders (formal PO before receiving goods)
CREATE TABLE purchase_orders (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id       BIGINT UNSIGNED NOT NULL,
  branch_id       BIGINT UNSIGNED NOT NULL,
  warehouse_id    BIGINT UNSIGNED,
  contact_id      BIGINT UNSIGNED NOT NULL,    -- supplier
  ref_no          VARCHAR(100),
  po_date         DATE NOT NULL,
  expected_date   DATE,
  status          ENUM('draft','sent','partial','received','cancelled') DEFAULT 'draft',
  total           DECIMAL(15,4) DEFAULT 0,
  tax_amount      DECIMAL(15,4) DEFAULT 0,
  shipping_cost   DECIMAL(15,4) DEFAULT 0,
  final_price     DECIMAL(15,4) DEFAULT 0,
  notes           TEXT,
  created_by      BIGINT UNSIGNED NOT NULL,
  created_at      TIMESTAMP,
  updated_at      TIMESTAMP,
  deleted_at      TIMESTAMP NULL,
  INDEX idx_tenant (tenant_id)
);

CREATE TABLE purchase_order_lines (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  purchase_order_id BIGINT UNSIGNED NOT NULL,
  product_id        BIGINT UNSIGNED NOT NULL,
  unit_id           BIGINT UNSIGNED NOT NULL,
  quantity_ordered  DECIMAL(15,4) NOT NULL,
  quantity_received DECIMAL(15,4) DEFAULT 0,
  unit_price        DECIMAL(15,4) NOT NULL,
  tax_rate          DECIMAL(5,2) DEFAULT 0,
  total             DECIMAL(15,4) NOT NULL,
  FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE
);
```

### 3.9 HR & Payroll (New — Complete Module)

```sql
-- Departments
CREATE TABLE departments (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id   BIGINT UNSIGNED NOT NULL,
  branch_id   BIGINT UNSIGNED,
  parent_id   BIGINT UNSIGNED,
  name        VARCHAR(255) NOT NULL,
  code        VARCHAR(50),
  manager_id  BIGINT UNSIGNED,                 -- FK employees
  is_active   TINYINT(1) DEFAULT 1,
  created_at  TIMESTAMP,
  updated_at  TIMESTAMP,
  INDEX idx_tenant (tenant_id)
);

-- Job Positions
CREATE TABLE job_positions (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id   BIGINT UNSIGNED NOT NULL,
  department_id BIGINT UNSIGNED,
  title       VARCHAR(255) NOT NULL,
  description TEXT,
  min_salary  DECIMAL(15,4),
  max_salary  DECIMAL(15,4),
  is_active   TINYINT(1) DEFAULT 1,
  created_at  TIMESTAMP,
  updated_at  TIMESTAMP,
  INDEX idx_tenant (tenant_id)
);

-- Employees
CREATE TABLE employees (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id         BIGINT UNSIGNED NOT NULL,
  user_id           BIGINT UNSIGNED,             -- linked to system user (optional)
  branch_id         BIGINT UNSIGNED,
  department_id     BIGINT UNSIGNED,
  job_position_id   BIGINT UNSIGNED,
  employee_code     VARCHAR(50),
  first_name        VARCHAR(100) NOT NULL,
  last_name         VARCHAR(100) NOT NULL,
  national_id       VARCHAR(50),
  gender            ENUM('male','female'),
  birth_date        DATE,
  hire_date         DATE NOT NULL,
  termination_date  DATE,
  employment_type   ENUM('full_time','part_time','contractor','intern') DEFAULT 'full_time',
  status            ENUM('active','inactive','on_leave','terminated') DEFAULT 'active',
  email             VARCHAR(255),
  phone             VARCHAR(50),
  address           TEXT,
  governorate_id    BIGINT UNSIGNED,
  city_id           BIGINT UNSIGNED,
  bank_account_no   VARCHAR(100),
  bank_name         VARCHAR(255),
  base_salary       DECIMAL(15,4) NOT NULL DEFAULT 0,
  salary_type       ENUM('monthly','daily','hourly') DEFAULT 'monthly',
  created_at        TIMESTAMP,
  updated_at        TIMESTAMP,
  deleted_at        TIMESTAMP NULL,
  INDEX idx_tenant (tenant_id),
  INDEX idx_tenant_code (tenant_id, employee_code)
);

-- Attendance
CREATE TABLE attendance_logs (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id    BIGINT UNSIGNED NOT NULL,
  employee_id  BIGINT UNSIGNED NOT NULL,
  date         DATE NOT NULL,
  check_in     TIMESTAMP NULL,
  check_out    TIMESTAMP NULL,
  status       ENUM('present','absent','late','half_day','leave') DEFAULT 'present',
  work_hours   DECIMAL(5,2) GENERATED ALWAYS AS (
                TIMESTAMPDIFF(MINUTE, check_in, check_out) / 60
               ) STORED,
  overtime_hours DECIMAL(5,2) DEFAULT 0,
  note         TEXT,
  created_at   TIMESTAMP,
  updated_at   TIMESTAMP,
  UNIQUE KEY unique_employee_date (tenant_id, employee_id, date),
  INDEX idx_tenant_date (tenant_id, date)
);

-- Leave Management
CREATE TABLE leave_types (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id     BIGINT UNSIGNED NOT NULL,
  name          VARCHAR(100) NOT NULL,           -- 'Annual', 'Sick', 'Emergency'
  days_allowed  INT DEFAULT 0,
  is_paid       TINYINT(1) DEFAULT 1,
  created_at    TIMESTAMP,
  updated_at    TIMESTAMP
);

CREATE TABLE leave_requests (
  id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id      BIGINT UNSIGNED NOT NULL,
  employee_id    BIGINT UNSIGNED NOT NULL,
  leave_type_id  BIGINT UNSIGNED NOT NULL,
  start_date     DATE NOT NULL,
  end_date       DATE NOT NULL,
  days_count     INT NOT NULL,
  reason         TEXT,
  status         ENUM('pending','approved','rejected') DEFAULT 'pending',
  approved_by    BIGINT UNSIGNED,
  approved_at    TIMESTAMP NULL,
  rejection_note TEXT,
  created_at     TIMESTAMP,
  updated_at     TIMESTAMP,
  INDEX idx_tenant_employee (tenant_id, employee_id)
);

-- Salary Components (allowances, deductions)
CREATE TABLE salary_components (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id     BIGINT UNSIGNED NOT NULL,
  name          VARCHAR(255) NOT NULL,           -- 'Housing Allowance', 'Social Insurance'
  type          ENUM('allowance','deduction') NOT NULL,
  calculation   ENUM('fixed','percentage') DEFAULT 'fixed',
  value         DECIMAL(15,4) DEFAULT 0,
  is_taxable    TINYINT(1) DEFAULT 0,
  is_active     TINYINT(1) DEFAULT 1,
  created_at    TIMESTAMP,
  updated_at    TIMESTAMP,
  INDEX idx_tenant (tenant_id)
);

-- Employee Salary Components (per employee overrides)
CREATE TABLE employee_salary_components (
  id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id         BIGINT UNSIGNED NOT NULL,
  salary_component_id BIGINT UNSIGNED NOT NULL,
  value               DECIMAL(15,4) NOT NULL,
  effective_from      DATE,
  effective_to        DATE,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

-- Payroll Runs
CREATE TABLE payroll_periods (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id     BIGINT UNSIGNED NOT NULL,
  name          VARCHAR(100),                    -- 'March 2025 Payroll'
  period_start  DATE NOT NULL,
  period_end    DATE NOT NULL,
  payment_date  DATE,
  status        ENUM('draft','approved','paid') DEFAULT 'draft',
  total_gross   DECIMAL(15,4) DEFAULT 0,
  total_net     DECIMAL(15,4) DEFAULT 0,
  total_deductions DECIMAL(15,4) DEFAULT 0,
  processed_by  BIGINT UNSIGNED,
  created_at    TIMESTAMP,
  updated_at    TIMESTAMP,
  INDEX idx_tenant (tenant_id)
);

CREATE TABLE payroll_slips (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id         BIGINT UNSIGNED NOT NULL,
  payroll_period_id BIGINT UNSIGNED NOT NULL,
  employee_id       BIGINT UNSIGNED NOT NULL,
  base_salary       DECIMAL(15,4) NOT NULL,
  total_allowances  DECIMAL(15,4) DEFAULT 0,
  total_deductions  DECIMAL(15,4) DEFAULT 0,
  overtime_pay      DECIMAL(15,4) DEFAULT 0,
  gross_salary      DECIMAL(15,4) NOT NULL,
  tax_amount        DECIMAL(15,4) DEFAULT 0,
  net_salary        DECIMAL(15,4) NOT NULL,
  working_days      INT DEFAULT 0,
  absent_days       INT DEFAULT 0,
  leave_days        INT DEFAULT 0,
  payment_method    ENUM('bank_transfer','cash','check') DEFAULT 'bank_transfer',
  paid_at           TIMESTAMP NULL,
  lines             JSON,                        -- breakdown of components
  created_at        TIMESTAMP,
  updated_at        TIMESTAMP,
  UNIQUE KEY unique_slip (tenant_id, payroll_period_id, employee_id),
  INDEX idx_tenant (tenant_id)
);
```

### 3.10 Reporting & Analytics Support Tables

```sql
-- Report Templates (saved reports)
CREATE TABLE report_templates (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id    BIGINT UNSIGNED NOT NULL,
  name         VARCHAR(255) NOT NULL,
  module       VARCHAR(100),                     -- 'sales', 'inventory', 'hr'
  filters      JSON,                             -- saved filter configuration
  columns      JSON,                             -- which columns to show
  is_shared    TINYINT(1) DEFAULT 0,
  created_by   BIGINT UNSIGNED NOT NULL,
  created_at   TIMESTAMP,
  updated_at   TIMESTAMP,
  INDEX idx_tenant (tenant_id)
);

-- Scheduled Reports
CREATE TABLE scheduled_reports (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id         BIGINT UNSIGNED NOT NULL,
  report_template_id BIGINT UNSIGNED,
  name              VARCHAR(255) NOT NULL,
  frequency         ENUM('daily','weekly','monthly') NOT NULL,
  send_at           TIME,
  recipients        JSON,                        -- ['email1@x.com', 'email2@x.com']
  format            ENUM('pdf','excel','csv') DEFAULT 'pdf',
  is_active         TINYINT(1) DEFAULT 1,
  last_sent_at      TIMESTAMP NULL,
  created_by        BIGINT UNSIGNED NOT NULL,
  created_at        TIMESTAMP,
  updated_at        TIMESTAMP
);

-- KPI Snapshots (for dashboard performance)
CREATE TABLE kpi_snapshots (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id    BIGINT UNSIGNED NOT NULL,
  date         DATE NOT NULL,
  metric       VARCHAR(100) NOT NULL,            -- 'total_sales', 'gross_profit', 'new_customers'
  value        DECIMAL(20,4) NOT NULL,
  branch_id    BIGINT UNSIGNED,
  created_at   TIMESTAMP,
  UNIQUE KEY unique_kpi (tenant_id, date, metric, branch_id),
  INDEX idx_tenant_metric (tenant_id, metric, date)
);
```

---

## 4. Module Feature Plan

### Module 1: Auth & Roles
- [x] Multi-tenant login (subdomain-based)
- [x] OAuth2 via Laravel Passport (access + refresh tokens)
- [x] Role-based permissions via Spatie (team mode for tenants)
- [ ] Two-Factor Authentication (TOTP)
- [ ] Password policy enforcement
- [ ] Session management (view & revoke active tokens)
- [ ] IP whitelist per tenant
- [ ] SSO readiness (OAuth2 provider)

### Module 2: Tenant Management (Super Admin)
- [ ] Tenant CRUD (super admin panel)
- [ ] Subscription plan management via Cashier (Stripe)
- [ ] Trial period management
- [ ] Tenant onboarding wizard (setup branches, settings, first user)
- [ ] Per-tenant feature flags (enable/disable modules per plan)
- [ ] Tenant usage analytics (API calls, storage, users)
- [ ] Tenant suspend/reactivate

### Module 3: Contacts (Customers & Suppliers)
- [x] Unified contact model (type: customer | supplier)
- [x] Sales segments with custom pricing
- [ ] Contact import (Excel/CSV via Laravel Excel)
- [ ] Contact merge (deduplication)
- [ ] Contact statement (balance sheet per contact)
- [ ] Credit limit enforcement at transaction creation
- [ ] Bulk email/SMS to contact segments
- [ ] Contact portal (optional customer login to view invoices)

### Module 4: Products
- [x] Multi-unit support (kg, box, carton with conversion)
- [x] Price per unit type
- [x] Product-branch assignment
- [ ] Product variants (color, size) - variable products
- [ ] Barcode generation & printing
- [ ] Product import (Excel)
- [ ] Combo/bundle products
- [ ] Product image gallery (Spatie Medialibrary)
- [ ] Price lists (customer-segment specific pricing)
- [ ] Product tags & advanced filtering
- [ ] Low stock alerts (queue job via Horizon)

### Module 5: Inventory Management
- [x] Stock per branch tracking
- [ ] Multi-warehouse support
- [ ] Full stock movement ledger
- [ ] Batch/lot tracking
- [ ] Expiry date tracking & alerts
- [ ] Serial number tracking
- [ ] Stock adjustments (physical count workflow with approval)
- [ ] Inter-warehouse transfers
- [ ] Stock valuation (FIFO / Weighted Average / LIFO)
- [ ] Reorder point automation (auto-create PO drafts)
- [ ] Spoilage / waste management

### Module 6: Sales & CRM
- [x] Sales invoices (cash + credit)
- [x] Sales returns
- [x] Delivery status tracking
- [ ] Quotations → convert to invoice
- [ ] Sales orders
- [ ] CRM: Lead pipeline (Kanban view)
- [ ] CRM: Activity log (calls, meetings, tasks)
- [ ] Customer statements
- [ ] Sales rep assignment + commission tracking
- [ ] Recurring invoices
- [ ] Invoice PDF generation & email delivery
- [ ] POS (Point of Sale) mode for walk-in sales

### Module 7: Purchasing
- [x] Purchase invoices
- [x] Purchase returns
- [ ] Purchase Orders (formal PO → receive goods workflow)
- [ ] Supplier statements
- [ ] Purchase request workflow (approval chain)
- [ ] Three-way matching (PO → Receipt → Invoice)
- [ ] Landed costs allocation
- [ ] Supplier performance scoring

### Module 8: Finance & Accounting
- [x] Basic cash accounts
- [x] Payment tracking
- [ ] Full Chart of Accounts (double-entry)
- [ ] Journal entries (auto-generated + manual)
- [ ] Tax management (VAT, withholding)
- [ ] Cost center tracking
- [ ] Bank reconciliation
- [ ] Financial statements: P&L, Balance Sheet, Cash Flow
- [ ] Budget vs Actual
- [ ] Fiscal year management
- [ ] Multi-currency support
- [ ] Audit trail for all financial entries

### Module 9: HR & Payroll
- [ ] Employee profiles & documents
- [ ] Department & position hierarchy
- [ ] Attendance (manual + device integration-ready)
- [ ] Leave management (request → approve workflow)
- [ ] Overtime calculation
- [ ] Salary structure (base + allowances + deductions)
- [ ] Payroll run with slip generation
- [ ] Payroll PDF & email to employees
- [ ] Social insurance & income tax calculation (Egypt)
- [ ] HR reports: headcount, turnover, attendance summary

### Module 10: Reporting & Analytics
- [ ] Dashboard with KPI cards (sales, purchases, inventory, HR)
- [ ] Sales reports: by product, branch, rep, period, customer
- [ ] Purchase reports: by supplier, product, period
- [ ] Inventory reports: stock value, movement, aging
- [ ] Finance reports: P&L, Balance Sheet, trial balance
- [ ] HR reports: payroll summary, attendance, leave
- [ ] Custom report builder
- [ ] Scheduled reports (email PDF/Excel on schedule)
- [ ] Data export (PDF, Excel, CSV)
- [ ] Charts: Line, Bar, Pie (via API response to frontend)

---

## 5. Package & Dependency Plan

### Backend Packages (composer.json)

```json
{
  "require": {
    "php": "^8.3",
    "laravel/framework": "^13.0",

    // === AUTHENTICATION ===
    "laravel/passport": "^13.0",

    // === AUTHORIZATION ===
    "spatie/laravel-permission": "^6.0",

    // === BILLING / SAAS ===
    "laravel/cashier": "^15.0",

    // === ACTIVITY LOG ===
    "spatie/laravel-activitylog": "^4.0",

    // === QUEUE MANAGEMENT ===
    "laravel/horizon": "^5.0",

    // === MEDIA / FILE UPLOAD ===
    "spatie/laravel-medialibrary": "^11.0",

    // === EXCEL / CSV IMPORT-EXPORT ===
    "maatwebsite/laravel-excel": "^4.0",

    // === PDF GENERATION ===
    "barryvdh/laravel-dompdf": "^3.0",

    // === NOTIFICATIONS ===
    // Built-in Laravel Notifications (email, SMS, database, broadcast)
    // SMS gateway (choose one):
    "vonage/laravel": "^4.0",               // or twilio/sdk

    // === SETTINGS ===
    "spatie/laravel-settings": "^3.0",      // typed settings per tenant

    // === FILTERING / QUERY BUILDER ===
    "spatie/laravel-query-builder": "^5.0", // API filter/sort/include

    // === API RESOURCES & RESPONSE ===
    "spatie/laravel-data": "^4.0",          // typed DTOs for API responses

    // === CACHING ===
    // Built-in Laravel Cache (Redis)

    // === SEARCH ===
    "laravel/scout": "^10.0",               // full-text search
    "meilisearch/meilisearch-php": "^1.0",  // Meilisearch driver (recommended)

    // === BACKUP ===
    "spatie/laravel-backup": "^9.0",

    // === RATE LIMITING ===
    // Built-in Laravel throttle middleware

    // === TELESCOPE (Dev Only) ===
    "laravel/telescope": "^5.0",

    // === BARCODE ===
    "picqer/php-barcode-generator": "^2.0",

    // === MONEY / CURRENCY ===
    "moneyphp/money": "^4.0",

    // === SLACK NOTIFICATIONS ===
    "laravel/slack-notification-channel": "^3.0"
  },
  "require-dev": {
    "laravel/telescope": "^5.0",
    "pestphp/pest": "^3.0",
    "pestphp/pest-plugin-laravel": "^3.0",
    "nunomaduro/collision": "^8.0",
    "fakerphp/faker": "^1.23"
  }
}
```


### Infrastructure / DevOps
```
PHP 8.3+
MySQL 8.0+ (with JSON support, generated columns, full-text)
Redis 7+              → Cache + Queues (Horizon) + Sessions + Rate Limiting
Meilisearch           → Product/Contact search
MinIO / S3            → Media storage (Spatie Medialibrary)
Nginx                 → Web server
Supervisor            → Queue workers
Node.js 20+           → Asset compilation (Vite)
```

---

## 6. Module Architecture Structure

```
app/
├── Http/
│   ├── Middleware/
│   │   ├── SetTenantScope.php          ← tenant resolver
│   │   ├── EnsureTenantIsActive.php
│   │   └── CheckSubscriptionPlan.php
│   └── Kernel.php
│
├── Models/
│   └── Concerns/
│       └── BelongsToTenant.php         ← global scope trait
│
Modules/                                ← module-based structure
├── Auth/
│   ├── Controllers/
│   ├── Requests/
│   ├── Resources/
│   ├── Services/
│   └── routes.php
│
├── Tenants/
│   ├── Models/Tenant.php
│   ├── Models/SubscriptionPlan.php
│   ├── Controllers/
│   ├── Services/TenantService.php
│   └── routes.php
│
├── Contacts/
│   ├── Models/Contact.php              ← uses BelongsToTenant
│   ├── Controllers/CustomerController.php
│   ├── Controllers/SupplierController.php
│   ├── Services/ContactStatementService.php
│   └── routes.php
│
├── Products/
│   ├── Models/{Product, Brand, Category, Unit, ProductUnitDetail}
│   ├── Controllers/
│   ├── Imports/ProductImport.php       ← Laravel Excel
│   ├── Services/BarcodeService.php
│   └── routes.php
│
├── Inventory/
│   ├── Models/{Warehouse, StockLevel, StockMovement, ProductBatch}
│   ├── Controllers/
│   ├── Services/StockValuationService.php
│   ├── Services/StockMovementService.php
│   ├── Jobs/LowStockAlertJob.php       ← Horizon queue
│   └── routes.php
│
├── Sales/
│   ├── Models/{Transaction, TransactionSellLine, Quotation}
│   ├── Controllers/
│   ├── Services/SaleService.php
│   ├── Services/QuotationService.php
│   ├── Jobs/GenerateInvoicePdfJob.php  ← Horizon queue
│   └── routes.php
│
├── CRM/
│   ├── Models/{CrmLead, CrmActivity}
│   ├── Controllers/
│   ├── Services/LeadService.php
│   └── routes.php
│
├── Purchasing/
│   ├── Models/{PurchaseOrder, PurchaseOrderLine}
│   ├── Controllers/
│   ├── Services/PurchaseReceivingService.php
│   └── routes.php
│
├── Finance/
│   ├── Models/{ChartOfAccount, JournalEntry, JournalEntryLine, Tax}
│   ├── Controllers/
│   ├── Services/JournalService.php     ← auto-posts entries
│   ├── Services/FinancialStatementService.php
│   └── routes.php
│
├── HR/
│   ├── Models/{Employee, Department, AttendanceLog, LeaveRequest, PayrollPeriod}
│   ├── Controllers/
│   ├── Services/PayrollService.php
│   ├── Services/AttendanceService.php
│   ├── Jobs/GeneratePayslipJob.php     ← Horizon queue
│   └── routes.php
│
├── Reporting/
│   ├── Controllers/
│   ├── Services/
│   │   ├── SalesReportService.php
│   │   ├── InventoryReportService.php
│   │   ├── FinanceReportService.php
│   │   └── HRReportService.php
│   ├── Jobs/ScheduledReportJob.php     ← Horizon queue
│   └── routes.php
│
└── Notifications/
    ├── LowStockNotification.php
    ├── InvoiceGeneratedNotification.php
    ├── PayrollProcessedNotification.php
    └── LeaveRequestNotification.php
```

---

## 7. Queue & Job Strategy (Horizon)

### Queue Priority Configuration
```php
// config/horizon.php
'environments' => [
    'production' => [
        'supervisor-critical' => [
            'queues' => ['critical'],           // payment processing, auth
            'processes' => 5,
            'tries' => 3,
        ],
        'supervisor-default' => [
            'queues' => ['default', 'invoices', 'notifications'],
            'processes' => 10,
            'tries' => 3,
        ],
        'supervisor-reports' => [
            'queues' => ['reports', 'exports', 'imports'],
            'processes' => 5,
            'tries' => 1,
            'timeout' => 300,                  // 5 min for heavy reports
        ],
    ],
],
```

### Jobs by Queue

| Queue | Job | Trigger |
|---|---|---|
| `critical` | `ProcessPaymentJob` | Payment submitted |
| `invoices` | `GenerateInvoicePdfJob` | Invoice created |
| `invoices` | `SendInvoiceEmailJob` | Invoice finalized |
| `notifications` | `SendLowStockAlertJob` | Stock < alert level |
| `notifications` | `SendPaymentReminderJob` | Scheduled (daily) |
| `reports` | `GenerateSalesReportJob` | Manual trigger |
| `reports` | `ScheduledReportJob` | Cron (daily/weekly/monthly) |
| `exports` | `ExportTransactionsJob` | User export request |
| `imports` | `ImportProductsJob` | File upload |
| `imports` | `ImportContactsJob` | File upload |
| `default` | `GeneratePayslipJob` | Payroll run approved |
| `default` | `TakeKpiSnapshotJob` | Nightly cron |

---

## 8. API & Auth Strategy (Passport)

### OAuth2 Flows Supported
- **Password Grant** → Mobile app / SPA login (username + password → access token)
- **Client Credentials** → Server-to-server (third-party integrations)
- **Refresh Token** → Silent re-auth when access token expires

### Token Scopes (by Module)
```php
Passport::tokensCan([
    'sales:read'        => 'View sales transactions',
    'sales:write'       => 'Create/edit sales',
    'inventory:read'    => 'View stock levels',
    'inventory:write'   => 'Adjust stock',
    'finance:read'      => 'View financial reports',
    'finance:write'     => 'Post journal entries',
    'hr:read'           => 'View employee data',
    'hr:write'          => 'Manage HR & payroll',
    'reports:view'      => 'Generate and view reports',
    'admin'             => 'Full tenant admin access',
]);
```

### API Versioning
```
/api/v1/           ← stable (current)
/api/v2/           ← future breaking changes
```

---

## 9. Roles & Permissions Strategy (Spatie)

### Enable Team Mode (Required for Multi-Tenancy)
```php
// config/permission.php
'teams' => true,
'team_foreign_key' => 'tenant_id',
```

### Seeded Permission Naming Convention
Format: `module.resource.action`

```
// Sales
sales.invoices.view
sales.invoices.create
sales.invoices.update
sales.invoices.delete
sales.returns.create
sales.quotations.create
sales.quotations.approve

// Inventory
inventory.products.view
inventory.products.create
inventory.products.update
inventory.stock.adjust
inventory.transfers.create

// Finance
finance.accounts.view
finance.journal.create
finance.reports.view
finance.settings.update

// HR
hr.employees.view
hr.employees.create
hr.payroll.run
hr.attendance.view
hr.leave.approve

// Admin
admin.users.manage
admin.roles.manage
admin.branches.manage
admin.settings.manage
admin.subscriptions.manage
```

### Default Roles Per Tenant
| Role | Permissions |
|---|---|
| `Super Admin` | All permissions |
| `Branch Manager` | All module permissions for their branch |
| `Sales Rep` | sales.*.view + sales.invoices.create |
| `Cashier` | sales.invoices.create + payments.create |
| `Accountant` | finance.*.all |
| `HR Manager` | hr.*.all |
| `Inventory Clerk` | inventory.*.all |
| `Viewer` | *.view only |

---

## 10. Reporting & Analytics Strategy

### Key Reports by Module

**Sales Reports**
- Daily/Weekly/Monthly Sales Summary
- Sales by Product, Brand, Category
- Sales by Branch, Sales Rep
- Customer Account Statement
- Top N Customers
- Payment collection report

**Inventory Reports**
- Current Stock Value (by FIFO / weighted avg)
- Stock Movement Ledger
- Product Aging Report
- Low Stock Alert Report
- Spoilage Report
- Inventory Turnover

**Finance Reports**
- Profit & Loss Statement
- Balance Sheet
- Trial Balance
- Cash Flow Statement
- Tax Report (VAT)
- Expense Summary

**HR Reports**
- Payroll Summary Sheet
- Attendance Summary (monthly)
- Leave Balance Report
- Headcount Report

### Export Strategy
- **PDF** → `barryvdh/laravel-dompdf` (Blade templates)
- **Excel** → `maatwebsite/laravel-excel` (styled sheets)
- **CSV** → Streamed directly from DB for large datasets
- All exports dispatched as Horizon jobs for large date ranges

---

## 11. Development Phases Roadmap

### Phase 1 — Foundation (Weeks 1–4)
- [ ] DB migration: add `tenant_id` to all tables, rename `branchs` → `branches`
- [ ] Create `tenants`, `tenant_settings`, `subscription_plans` tables
- [ ] Implement `BelongsToTenant` global scope trait
- [ ] Laravel Passport setup (OAuth2)
- [ ] Spatie Permissions (team mode, seed permissions & default roles)
- [ ] Tenant resolver middleware
- [ ] Super admin panel (tenant CRUD)
- [ ] Module folder structure scaffold

### Phase 2 — Core Transactions (Weeks 5–10)
- [ ] Products module (with Medialibrary, barcode, import)
- [ ] Contacts module (customers + suppliers)
- [ ] Sales invoices & returns
- [ ] Purchase invoices & returns
- [ ] Inventory: stock levels, movements, warehouses
- [ ] Payments & basic accounts
- [ ] Horizon setup with queues
- [ ] Invoice PDF generation (Horizon job)

### Phase 3 — Finance & Accounting (Weeks 11–15)
- [ ] Chart of Accounts
- [ ] Double-entry journal (auto-generated from transactions)
- [ ] Tax module
- [ ] Expense management (enhanced)
- [ ] Financial statements (P&L, Balance Sheet)
- [ ] Bank reconciliation

### Phase 4 — HR & Payroll (Weeks 16–20)
- [ ] Employees, departments, positions
- [ ] Attendance management
- [ ] Leave management (with approval workflow)
- [ ] Salary structure & components
- [ ] Payroll run & payslip generation
- [ ] HR reports

### Phase 5 — CRM & Advanced Sales (Weeks 21–24)
- [ ] Quotations & sales orders
- [ ] CRM: Leads & pipeline
- [ ] CRM: Activities
- [ ] Sales commissions
- [ ] Customer portal

### Phase 6 — Reporting, Billing & Polish (Weeks 25–28)
- [ ] Full reporting module (all reports)
- [ ] Scheduled reports (Horizon cron jobs)
- [ ] Cashier/Stripe billing integration
- [ ] KPI dashboard with snapshots
- [ ] Notifications (email/SMS/in-app)
- [ ] System health & monitoring
- [ ] Full test suite (Pest)
- [ ] Deployment automation

---

## Quick Reference: Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Table names | `snake_case`, plural | `journal_entries` |
| Column names | `snake_case` | `tenant_id`, `created_by` |
| Money columns | `DECIMAL(15,4)` always | `unit_price DECIMAL(15,4)` |
| Timestamps | `TIMESTAMP NULL` | `deleted_at TIMESTAMP NULL` |
| Boolean flags | `TINYINT(1)` with default | `is_active TINYINT(1) DEFAULT 1` |
| Tenant scope | Second column always | `id, tenant_id, ...` |
| Composite indexes | `idx_tenant_*` | `INDEX idx_tenant_type (tenant_id, type)` |
| Permission names | `module.resource.action` | `sales.invoices.create` |
| Queue names | lowercase, descriptive | `reports`, `invoices`, `imports` |
| API routes | `/api/v1/module/resource` | `/api/v1/sales/invoices` |

---

*Generated for: Rakeeza ERP System — Laravel 13 · Single DB Multi-Tenancy · Module Architecture*