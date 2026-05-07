# Rakeeza ERP — Commercial/Trading ERP Plan

A commercial ERP built with Laravel 13 Module-Based Clean Architecture on a single physical database containing both central and tenant-scoped tables, covering sales, purchasing, inventory, finance, HR, and reporting.

---

## 1. Architecture Decisions

| Decision | Value | Rationale |
|---|---|---|
| **Tenancy** | One physical database; central tables + tenant-scoped tables coexist. All tenant tables have `tenant_id`. | User-mandated. |
| **Primary Keys** | `CHAR(36)` UUID Standard From Laravel | Follows `CURSOR_RULES.md` for portability and merge safety. |
| **Auth** | JWT (JSON Web Tokens) | tymon-jwt-auth. |
| **Authorization** | `spatie/laravel-permission` inside tenant DB |  roles/permissions scoped per tenant. |
| **Billing** | `laravel/cashier` | SaaS subscription plans for tenants. |
| **Queues** | Laravel Horizon (Redis) For Production Monitoring | Heavy operations: reports, imports, emails, notifications. |
| **Activity Log** | Custom `ActivityLog` module | Custom audit trail module; all other modules depend on it. |
| **Languages** | Arabic (primary) + English | All user-facing text fields bilingual (`name_ar` / `name_en`). |
| **API Response** | `ApiResponse` helper | Consistent JSON envelope across all endpoints. |
| **Architecture** | Module-Based Clean Architecture (`Application/Domain/Infrastructure/Presentation`) | `CURSOR_RULES.md` internal structure per module. |

---

## 2. Database Strategy

### Central DB Tables

| Table | Purpose |
|---|---|
| `tenants` | Tenant registry: name, slug, domain, status, plan_id, trial_ends_at |
| `plans` | Subscription tiers (features, limits, pricing) |
| `plan_features` / `features` | Feature flags per plan |
| `subscriptions` | Cashier-managed tenant subscriptions |
| `subscription_history` | Plan changes, renewals, cancellations |
| `invoices` | SaaS billing invoices |
| `payments` / `payment_transactions` | Payment ledger for subscriptions |
| `refunds` | Refund records |
| `platform_users` | Super-admin and support staff (central) |
| `domains` | Tenant custom domain mappings |
| `contact_requests` / `demo_requests` | Lead capture |
| `platform_notifications` | Cross-tenant platform announcements |
| `platform_notification_targets` | Delivery tracking |
| `audit_logs` | Central-level audit (tenant provisioning, billing) |

### Tenant DB Tables (all prefixed with `tenant_id`)

| Module | Tables |
|---|---|
| **Auth & Users** | `users`, `roles`, `permissions`, `role_user`, `permission_user`, `permission_role` |
| **CRM** | `contacts` (customers + suppliers, `type` enum), `contact_groups`, `contact_addresses`, `contact_notes`, `lead_activities` |
| **Products** | `products`, `brands`, `categories`, `units`, `product_unit_details`, `product_variants`, `product_branch_details` |
| **Inventory** | `warehouses`, `warehouse_locations`, `stock_movements`, `inventory_adjustments`, `stock_transfers` |
| **Sales** | `transactions` (type = `sell`), `transaction_sell_lines`, `sales_returns`, `sales_return_lines`, `pos_sessions` |
| **Purchasing** | `transactions` (type = `purchase`), `transaction_purchase_lines`, `purchase_returns`, `purchase_return_lines`, `purchase_orders` |
| **Finance** | `chart_of_accounts`, `journal_entries`, `journal_entry_lines`, `accounts`, `transfers` |
| **Payments** | `payments`, `payment_transactions` (customer/supplier payments) |
| **Expenses** | `expenses`, `expense_categories` |
| **HR** | `employees`, `departments`, `designations`, `attendances`, `leaves`, `leave_types`, `payrolls`, `payroll_items`, `salary_structures` |
| **Settings** | `settings`, `tax_rates`, `currencies`, `business_locations` |
| **Media** | `media_files` (unified file table) |
| **Audit** | `tenant_audit_logs` |

**Rule**: Every tenant table has `tenant_id BINARY(16) NOT NULL` as the second column after the primary key. All queries must scope on `tenant_id`.

---

## 3. Module Inventory

All modules live under `app/Modules/` with `Application/Domain/Infrastructure/Presentation` layers.

### Central Modules

| Module | Purpose | Priority |
|---|---|---|
| `Core` | `HasUuid`, `ApiResponse`, `PaginationMeta`, `SetLocale` middleware, base provider | **P0** |
| `Tenants` | Tenant CRUD, onboarding, provisioning, domain management | P1 |
| `PlatformUsers` | Super-admin and support staff (central) | P1 |
| `Plans` | Subscription tier management | P2 |
| `Billing` | Cashier integration, invoices, payments, refunds | P2 |

### Tenant Modules

| Module | Purpose | Priority |
|---|---|---|
| `Auth` | Login, register, password reset, email verification, token refresh | **P0** |
| `Users` | Tenant user CRUD, profile management | P1 |
| `Roles` | Role & permission CRUD, assignment | P1 |
| `Contacts` | Customers & suppliers (CRM) | P1 |
| `Products` | Product catalog: brands, categories, units, variants | P1 |
| `Inventory` | Warehouses, stock movements, adjustments, transfers | P1 |
| `Sales` | Sales invoices, returns, POS, quotations | P2 |
| `Purchasing` | Purchase orders, invoices, returns, supplier management | P2 |
| **Finance** | Chart of accounts, journal entries, transfers | P2 |
| `Payments` | Customer & supplier payment recording | P2 |
| `Expenses` | Expense tracking & categorization | P2 |
| `HR` | Employees, attendance, leave, payroll, salary structures | P3 |
| `Reports` | Sales, purchase, inventory, financial, HR reports | P3 |
| `Settings` | Tax rates, currencies, business locations, tenant config | P1 |
| `Notifications` | In-app, email, SMS, push notifications | P2 |

---

## 4. Naming Conventions

Follow `CURSOR_RULES.md` §4 with domain-specific adaptations:

| Type | Convention | Example |
|---|---|---|
| Table | `snake_case` plural | `contacts`, `stock_movements` |
| Primary Key | `{singular}_id` UUID | `product_id`, `contact_id` |
| Foreign Key | `{referenced_singular}_id` | `contact_id`, `warehouse_id` |
| Bilingual col | `{name}_ar` / `{name}_en` | `name_ar`, `description_en` |
| Status enum | `status TINYINT` + PHPDoc | `1=active 2=inactive` |
| Boolean | `is_{state}` or `has_{feature}` | `is_active`, `is_customer`, `is_supplier` |
| Financial | `decimal(15,4)` | `unit_price`, `balance`, `amount` |
| Soft delete | `deleted_at` | Standard Laravel |

---

## 5. Route Prefixes

```
/api/v1/central/...     → Platform admin routes (Central DB)
/api/v1/auth/...        → Tenant auth (login, register, reset)
/api/v1/{module}/...    → Tenant routes (auto-scoped by tenant_id middleware)
```

---

## 6. Phased Roadmap

### Phase 0: Foundation (Week 1)

1. Create `ActivityLog` module: migration, model, repository, use cases for manual audit logging.
2. Create `Core` module: `HasUuid`, `ApiResponse`, `PaginationMeta`, `SetLocale` middleware, base service provider.
3. Configure `config/permission.php` for UUID morph keys (no teams).
4. Configure JWT guards: `platform` (central) and `api` (tenant).
5. Create `Tenants` central module: model, migration, controller, repository, use cases.
6. Create tenant-scoping middleware: auto-inject `tenant_id` from authenticated user's tenant.
7. Wire `routes/central.php` and tenant routes.

### Phase 1: Identity & Access (Weeks 2–3)

1. `PlatformUsers` (Central): super-admin CRUD.
2. `Auth` (Tenant): login via JWT, register, password reset, email verification.
3. `Users` (Tenant): user CRUD, profile, avatar, status management.
4. `Roles` (Tenant): role & permission CRUD using Spatie; seed default roles (admin, manager, cashier, sales, purchaser, accountant, hr).
5. Middleware: `permission:{resource}.{action}` on all tenant routes.
6. ActivityLog module records all auth & role mutations.

### Phase 2: CRM & Product Catalog (Weeks 4–5)

1. `Contacts` module: customer/supplier unified table (`type` enum), addresses, notes, groups, credit limits.
2. `Products` module: products, brands, categories, units, unit details, variants, bilingual names.
3. `Settings` module: tax rates, currencies, business locations.
4. Bulk import jobs (Excel) for contacts and products via Horizon `imports` queue.

### Phase 3: Inventory (Week 6)

1. `Inventory` module: warehouses, locations, stock movements (in/out/adjustment/transfer), current stock view.
2. Stock movement triggers (e.g., on sale/purchase auto-update stock).
3. Stock adjustment with reason and audit trail.

### Phase 4: Sales & Purchasing (Weeks 7–8)

1. `Sales` module: sales transactions, transaction lines, sales returns, POS sessions, quotations.
2. `Purchasing` module: purchase orders, purchase transactions, transaction lines, purchase returns.
3. `Payments` module: record payments against transactions (customer receipts, supplier payments).
4. Auto-generate reference numbers per tenant (prefix + sequence).

### Phase 5: Finance & Expenses (Weeks 9–10)

1. `Finance` module: chart of accounts (asset, liability, equity, income, expense), journal entries with double-entry lines, account transfers.
2. `Expenses` module: expense categories, expense recording with attachment support.
3. Link sales/purchase transactions to journal entries (auto-posting option).

### Phase 6: HR & Payroll (Weeks 11–12)

1. `HR` module: departments, designations, employees, attendance (check-in/out), leave types & requests.
2. `Payroll` module: salary structures, payroll generation, payroll items (earnings, deductions), payslip generation.
3. Attendance report jobs via Horizon `reports` queue.

### Phase 7: Billing, Notifications & Reports (Weeks 13–14)

1. `Billing` (Central): SaaS plans, tenant subscription lifecycle, invoicing via Cashier.
2. `Notifications` (Tenant): in-app inbox, email (SMTP), SMS (Vonage/Twilio), FCM push. Queue to Horizon `notifications`.
3. `Reports` module: sales summary, purchase summary, inventory valuation, profit/loss, balance sheet, HR attendance. Async generation via `reports` queue.

### Phase 8: Polish & Scale (Week 15+)

1. Central dashboard: tenant health, subscription status, revenue.
2. Performance: DB indexing review, query optimization, API response caching.
3. Data export (PDF/Excel) for all major reports.
4. API documentation (OpenAPI/Swagger).

---

## 7. Default Tenant Roles & Permissions

| Role | Typical Permissions |
|---|---|
| `admin` | All permissions |
| `manager` | contacts.*, products.*, inventory.*, sales.*, purchasing.*, payments.*, expenses.*, reports.view |
| `sales` | contacts.view, products.view, sales.*, payments.* |
| `purchaser` | contacts.view, products.view, purchasing.*, payments.* |
| `accountant` | finance.*, payments.*, expenses.*, reports.view |
| `cashier` | pos.*, payments.*, contacts.view |
| `hr` | hr.*, employees.*, attendance.*, payroll.* |
| `viewer` | *.view only |

Permission naming: `{resource}.{action}` — e.g. `contact.create`, `sale.delete`, `inventory.adjust`, `report.view`.

---

## 8. Financial Precision Rule

All monetary columns **must** use `decimal(15,4)`. Never `double`, `float`, or `decimal(8,2)`.

---

## 9. Queue Strategy (Horizon)

| Queue | Purpose | Timeout |
|---|---|---|
| `default` | General async tasks | 60s |
| `notifications` | Email, SMS, push fan-out | 120s |
| `reports` | Heavy report generation | 300s |
| `imports` | Bulk CSV/Excel imports | 300s |
| `exports` | PDF/Excel generation | 300s |
| `billing` | Invoice generation, payment webhooks | 120s |

---

## 10. Definition of Done per Phase

| Phase | Done When |
|---|---|
| P0 | All packages installed; `Core` module importable; JWT guards configured; `Tenants` module creates tenant records; middleware scopes all queries by `tenant_id`. |
| P1 | Platform admin and tenant users can obtain tokens; roles/permissions seeded; unauthorized requests return 403 via `ApiResponse::error`; audit log records auth events. |
| P2 | Contacts and products are CRUD-able with bilingual validation; bulk import works via Horizon; settings (tax, currency) configurable. |
| P3 | Stock movements record correctly; inventory levels are queryable in real time; adjustments are auditable. |
| P4 | Sales and purchase transactions post with lines; returns correctly reverse stock; payments link to transactions; reference numbers auto-generate. |
| P5 | Journal entries balance (debits = credits); chart of accounts is hierarchical; expenses are categorized and reported. |
| P6 | Employee profiles, attendance, and payroll are operational; payslips generated async. |
| P7 | Tenant billing active via Cashier; notifications sent via all channels; reports generated async and cached. |
| P8 | Central dashboard shows metrics; API documented; performance targets met (< 200ms for standard endpoints). |

---

## 11. Notes on Legacy Files

- `CURSOR_RULES.md`: Still authoritative for **code patterns** (Clean Architecture structure, naming, API response envelope, UUIDs, bilingual fields, repository binding). Ignore its **school-specific modules** and **separate-DB tenancy** rules.
- `plan.md` / `claudi-plan.md`: Keep as historical references. Their schema snippets for `contacts`, `products`, `transactions`, `payments`, `expenses` are relevant to this commercial ERP and can inform table design once Phase 0 is solid.
