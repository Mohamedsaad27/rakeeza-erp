-- ============================================================
--  RAKEEZA ERP — Normalized & Modular Database Schema
--  MySQL 8.0+ · Single DB Multi-Tenancy · Laravel 13
--  Version: 4.0 | May 2025
-- ============================================================
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
--  CENTRAL · PLATFORM ADMINISTRATORS
-- ============================================================

CREATE TABLE `platform_users` (
  `id`                 CHAR(36)        NOT NULL,
  `name`               VARCHAR(255)    NOT NULL,
  `email`              VARCHAR(255)    NOT NULL,
  `password`           VARCHAR(255)    NOT NULL,
  `is_active`          TINYINT(1)      NOT NULL DEFAULT 1,
  `profile_image`      VARCHAR(255)    DEFAULT NULL,
  `email_verified_at`  TIMESTAMP       NULL DEFAULT NULL,
  `last_login_at`      TIMESTAMP       NULL DEFAULT NULL,
  `created_at`         TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`         TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`         TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `platform_users_email_unique` (`email`),
  KEY `platform_users_is_active_idx` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Central platform administrators (super-admins, support). Not tenant-scoped.';

-- ============================================================
--  MODULE 00 · TENANCY & SUBSCRIPTION
-- ============================================================


CREATE TABLE plans (
    plan_id CHAR(36) PRIMARY KEY,
    name VARCHAR(100),
    tenant_type TINYINT COMMENT '1=school | 2=academy | 3=private_tutor | 0=all',
    price DECIMAL(10,2),
    billing_cycle TINYINT COMMENT '1=monthly | 2=quarterly | 3=yearly',
    is_active BOOLEAN,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

CREATE TABLE plan_limits (
    plan_limit_id CHAR(36) PRIMARY KEY,
    plan_id CHAR(36),
    `key` VARCHAR(100),
    value INT,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,

    UNIQUE KEY uq_plan_key (plan_id, `key`),
    CONSTRAINT fk_plan_limits_plan
        FOREIGN KEY (plan_id) REFERENCES plans(plan_id)
        ON DELETE CASCADE
);

CREATE TABLE features (
    feature_id CHAR(36) PRIMARY KEY,
    name VARCHAR(150),
    code VARCHAR(150) UNIQUE,
    tenant_type TINYINT COMMENT '0=all | 1=school | 2=academy | 3=private_tutor',
    description TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMP NULL
);

CREATE TABLE plan_features (
    plan_feature_id CHAR(36) PRIMARY KEY,
    plan_id CHAR(36),
    feature_id CHAR(36),
    enabled BOOLEAN,

    UNIQUE KEY uq_plan_feature (plan_id, feature_id),

    CONSTRAINT fk_plan_features_plan
        FOREIGN KEY (plan_id) REFERENCES plans(plan_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_plan_features_feature
        FOREIGN KEY (feature_id) REFERENCES features(feature_id)
        ON DELETE CASCADE
);

-- =============================================
-- SUBSCRIPTIONS & BILLING
-- =============================================

CREATE TABLE subscriptions (
    subscription_id CHAR(36) PRIMARY KEY,
    tenant_id CHAR(36),
    plan_id CHAR(36),
    price_at_purchase DECIMAL(10,2),
    currency_at_purchase CHAR(3),
    status TINYINT COMMENT '1=active | 2=cancelled | 3=expired | 4=past_due',
    start_date TIMESTAMP,
    ends_at TIMESTAMP,
    auto_renew BOOLEAN,
    canceled_at TIMESTAMP NULL,
    cancel_reason VARCHAR(200),
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,

    INDEX idx_tenant_status (tenant_id, status),

    CONSTRAINT fk_subscriptions_plan
        FOREIGN KEY (plan_id) REFERENCES plans(plan_id)
);

CREATE TABLE subscription_history (
    history_id CHAR(36) PRIMARY KEY,
    subscription_id CHAR(36),
    tenant_id CHAR(36),
    old_plan_id CHAR(36),
    new_plan_id CHAR(36),
    change_type TINYINT COMMENT '1=upgrade | 2=downgrade | 3=renew | 4=cancel',
    changed_by CHAR(36),
    notes TEXT,
    created_at TIMESTAMP NULL,

    CONSTRAINT fk_sub_hist_subscription
        FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id),

    CONSTRAINT fk_sub_hist_old_plan
        FOREIGN KEY (old_plan_id) REFERENCES plans(plan_id),

    CONSTRAINT fk_sub_hist_new_plan
        FOREIGN KEY (new_plan_id) REFERENCES plans(plan_id)
);

CREATE TABLE invoices (
    invoice_id CHAR(36) PRIMARY KEY,
    tenant_id CHAR(36),
    subscription_id CHAR(36),
    invoice_number VARCHAR(30) UNIQUE,
    subtotal DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    discount_amount DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    paid_amount DECIMAL(10,2),
    currency CHAR(3),
    status TINYINT COMMENT '1=draft | 2=unpaid | 3=paid | 4=overdue | 5=cancelled',
    due_date DATE,
    issued_at TIMESTAMP,
    paid_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    cancellation_reason VARCHAR(255),
    metadata JSON,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,

    INDEX idx_invoice_tenant_status (tenant_id, status),
    INDEX idx_invoice_due (tenant_id, due_date),

    CONSTRAINT fk_invoice_subscription
        FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id)
);

CREATE TABLE payment_methods (
    payment_method_id TINYINT PRIMARY KEY,
    code VARCHAR(50) UNIQUE,
    name VARCHAR(100),
    is_active BOOLEAN
);

CREATE TABLE payments (
    payment_id CHAR(36) PRIMARY KEY,
    tenant_id CHAR(36),
    subscription_id CHAR(36),
    invoice_id CHAR(36),
    amount DECIMAL(10,2),
    currency CHAR(3),
    payment_method_id TINYINT,
    status TINYINT COMMENT '1=pending | 2=success | 3=failed',
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,

    CONSTRAINT fk_payments_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id),

    CONSTRAINT fk_payments_method
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id)
);

CREATE TABLE payment_transactions (
    transaction_id CHAR(36) PRIMARY KEY,
    payment_id CHAR(36),
    invoice_id CHAR(36),
    tenant_id CHAR(36),
    amount DECIMAL(10,2),
    currency CHAR(3),
    payment_method_id TINYINT,
    status TINYINT COMMENT '1=pending | 2=success | 3=failed',
    gateway_name VARCHAR(100),
    gateway_transaction_id VARCHAR(255),
    gateway_response JSON,
    ip_address VARBINARY(16),
    attempted_at TIMESTAMP,
    paid_at TIMESTAMP NULL,
    failed_at TIMESTAMP NULL,
    failure_reason VARCHAR(500),
    created_at TIMESTAMP NULL,

    INDEX idx_transaction_tenant_status (tenant_id, status),
    INDEX idx_transaction_payment (payment_id),

    CONSTRAINT fk_transactions_payment
        FOREIGN KEY (payment_id) REFERENCES payments(payment_id),

    CONSTRAINT fk_transactions_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id),

    CONSTRAINT fk_transactions_method
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id)
);

CREATE TABLE refunds (
    refund_id CHAR(36) PRIMARY KEY,
    transaction_id CHAR(36),
    payment_id CHAR(36),
    invoice_id CHAR(36),
    amount DECIMAL(10,2),
    reason TINYINT,
    notes TEXT,
    refunded_by CHAR(36),
    gateway_refund_id VARCHAR(255),
    status TINYINT COMMENT '1=pending | 2=processed | 3=failed',
    created_at TIMESTAMP NULL,
    processed_at TIMESTAMP NULL,

    CONSTRAINT fk_refunds_transaction
        FOREIGN KEY (transaction_id) REFERENCES payment_transactions(transaction_id),

    CONSTRAINT fk_refunds_payment
        FOREIGN KEY (payment_id) REFERENCES payments(payment_id),

    CONSTRAINT fk_refunds_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
);

-- ─────────────────────────────────────────────────────────
CREATE TABLE `tenants` (
  `id`            CHAR(36)        NOT NULL,
  `uuid`          CHAR(36)        NOT NULL COMMENT 'Used in subdomain routing',
  `name_en`       VARCHAR(255)    NOT NULL,
  `name_ar`       VARCHAR(255)    NOT NULL,
  `slug`          VARCHAR(100)    NOT NULL COMMENT 'subdomain slug: slug.rakeeza.com',
  `email`         VARCHAR(255)    NOT NULL COMMENT 'Owner / billing email',
  `phone`         VARCHAR(50)     DEFAULT NULL,
  `logo`          VARCHAR(500)    DEFAULT NULL,
  `status`        ENUM('active','suspended','cancelled') NOT NULL DEFAULT 'active',
  `trial_ends_at` TIMESTAMP       NULL DEFAULT NULL,
  `plan_id`       CHAR(36)        DEFAULT NULL,
  `created_at`    TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tenants_uuid_unique`  (`uuid`),
  UNIQUE KEY `tenants_slug_unique`  (`slug`),
  UNIQUE KEY `tenants_email_unique` (`email`),
  KEY `tenants_plan_id_foreign` (`plan_id`),
  CONSTRAINT `tenants_plan_id_foreign`
    FOREIGN KEY (`plan_id`) REFERENCES `subscription_plans` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One row per business/company using the SaaS platform.';

-- ─────────────────────────────────────────────────────────
CREATE TABLE `tenant_settings` (
  `id`                               CHAR(36)        NOT NULL,
  `tenant_id`                        CHAR(36)        NOT NULL,
  -- branding
  `logo`                             VARCHAR(500)    DEFAULT NULL,
  `site_image`                       VARCHAR(500)    DEFAULT NULL,
  `image_invoice`                    VARCHAR(500)    DEFAULT NULL,
  `site_name`                        VARCHAR(255)    DEFAULT NULL,
  -- locale
  `currency`                         VARCHAR(10)     NOT NULL DEFAULT 'EGP',
  `currency_symbol`                  VARCHAR(10)     NOT NULL DEFAULT 'ج.م',
  `date_format`                      VARCHAR(50)     NOT NULL DEFAULT 'Y-m-d',
  `time_zone`                        VARCHAR(100)    NOT NULL DEFAULT 'Africa/Cairo',
  `language`                         VARCHAR(10)     NOT NULL DEFAULT 'ar',
  -- tax & finance
  `tax_number`                       VARCHAR(100)    DEFAULT NULL,
  `default_tax_rate`                 DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
  `fiscal_year_start`                DATE            DEFAULT NULL,
  `default_credit_limit`             DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  -- behaviour flags
  `allow_unit_price_update`          TINYINT(1)      NOT NULL DEFAULT 0,
  `prevent_buy_below_purchase_price` TINYINT(1)      NOT NULL DEFAULT 1,
  -- printing
  `thermal_printing`                 TINYINT(1)      NOT NULL DEFAULT 0,
  `classic_printing`                 TINYINT(1)      NOT NULL DEFAULT 1,
  -- invoice display flags
  `invoice_display`                  JSON            NOT NULL DEFAULT ('{}')
    COMMENT 'Keys: total, discount, final_price, credit_details, contact_info, branch_info, date, created_by, ref_no',
  -- catalog display flags
  `catalog_display`                  JSON            NOT NULL DEFAULT ('{}')
    COMMENT 'Keys: brands, main_category, sub_category, sub_units',
  -- contact / social
  `email`                            VARCHAR(255)    DEFAULT NULL,
  `phone`                            VARCHAR(255)    DEFAULT NULL,
  `address`                          TEXT            DEFAULT NULL,
  `about_us`                         TEXT            DEFAULT NULL,
  `facebook`                         VARCHAR(255)    DEFAULT NULL,
  `instagram`                        VARCHAR(255)    DEFAULT NULL,
  `twitter`                          VARCHAR(255)    DEFAULT NULL,
  `linkedin`                         VARCHAR(255)    DEFAULT NULL,
  `invoice_footer_note`              TEXT            DEFAULT NULL,
  `created_at`                       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`                       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`                       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tenant_settings_tenant_id_unique` (`tenant_id`),
  CONSTRAINT `tenant_settings_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='All per-tenant configuration. One row per tenant.';


-- ============================================================
--  MODULE 01 · LOCATION  (shared reference data — no tenant_id)
-- ============================================================

CREATE TABLE `governorates` (
  `id`                   CHAR(36)        NOT NULL,
  `governorate_name_ar`  VARCHAR(255)    DEFAULT NULL,
  `governorate_name_en`  VARCHAR(255)    DEFAULT NULL,
  `created_at`           TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`           TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`           TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Egyptian governorates. Shared reference — no tenant_id.';

-- ─────────────────────────────────────────────────────────
CREATE TABLE `cities` (
  `id`             CHAR(36)        NOT NULL,
  `governorate_id` CHAR(36)        NOT NULL,
  `city_name_ar`   VARCHAR(255)    DEFAULT NULL,
  `city_name_en`   VARCHAR(255)    DEFAULT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cities_governorate_id_foreign` (`governorate_id`),
  CONSTRAINT `cities_governorate_id_foreign`
    FOREIGN KEY (`governorate_id`) REFERENCES `governorates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
--  MODULE 02 · AUTH — USERS & BRANCHES
--  JWT via Tymon (tymon/jwt-auth) — no OAuth tables needed.
--  Token blacklisting handled in cache/Redis by JWT package.
-- ============================================================

CREATE TABLE `branches` (
  `id`                CHAR(36)        NOT NULL,
  `tenant_id`         CHAR(36)        NOT NULL,
  `name_en`           VARCHAR(255)    NOT NULL,
  `name_ar`           VARCHAR(255)    NOT NULL,
  `code`              VARCHAR(50)     DEFAULT NULL,
  `address`           TEXT            DEFAULT NULL,
  `phone`             VARCHAR(50)     DEFAULT NULL,
  `is_main`           TINYINT(1)      NOT NULL DEFAULT 0,
  `is_active`         TINYINT(1)      NOT NULL DEFAULT 1,
  `governorate_id`    CHAR(36)        DEFAULT NULL,
  `city_id`           CHAR(36)        DEFAULT NULL,
  -- cash drawers (account_branch pivot eliminated)
  `cash_account_id`   CHAR(36)        DEFAULT NULL,
  `credit_account_id` CHAR(36)        DEFAULT NULL,
  `created_at`        TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`        TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`        TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `branches_tenant_id_idx`      (`tenant_id`),
  KEY `branches_governorate_id_fk`  (`governorate_id`),
  KEY `branches_city_id_fk`         (`city_id`),
  KEY `branches_cash_account_fk`    (`cash_account_id`),
  KEY `branches_credit_account_fk`  (`credit_account_id`),
  CONSTRAINT `branches_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)         REFERENCES `tenants`      (`id`) ON DELETE CASCADE,
  CONSTRAINT `branches_governorate_id_foreign`
    FOREIGN KEY (`governorate_id`)    REFERENCES `governorates` (`id`) ON DELETE SET NULL,
  CONSTRAINT `branches_city_id_foreign`
    FOREIGN KEY (`city_id`)           REFERENCES `cities`       (`id`) ON DELETE SET NULL
  -- cash/credit account FKs added after accounts table (deferred below)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Physical branches/locations per tenant.';

-- ─────────────────────────────────────────────────────────
CREATE TABLE `users` (
  `id`            CHAR(36)        NOT NULL,
  `tenant_id`     CHAR(36)        NOT NULL,
  `branch_id`     CHAR(36)        DEFAULT NULL COMMENT 'Default/home branch',
  `name`          VARCHAR(255)    NOT NULL,
  `username`      VARCHAR(255)    NOT NULL,
  `email`         VARCHAR(255)    DEFAULT NULL,
  `phone`         VARCHAR(50)     DEFAULT NULL,
  `avatar`        VARCHAR(500)    DEFAULT NULL,
  `password`      VARCHAR(255)    NOT NULL,
  `is_active`     TINYINT(1)      NOT NULL DEFAULT 1,
  `last_login_at` TIMESTAMP       NULL DEFAULT NULL,
  `verified_at`   TIMESTAMP       NULL DEFAULT NULL,
  -- remember_token removed: JWT is stateless, no server-side session needed
  `created_at`    TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  -- FIX v2: username and email unique keys now scoped per tenant
  UNIQUE KEY `users_tenant_username_unique` (`tenant_id`, `username`),
  UNIQUE KEY `users_tenant_email_unique`    (`tenant_id`, `email`),
  KEY `users_tenant_id_idx`    (`tenant_id`),
  KEY `users_branch_id_foreign` (`branch_id`),
  CONSTRAINT `users_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `users_branch_id_foreign`
    FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
--  JWT token blacklist handled by Tymon in cache/Redis.
--  We only store a password_resets table for the reset flow.
-- ─────────────────────────────────────────────────────────
CREATE TABLE `password_resets` (
  `id`         CHAR(36)        NOT NULL,
  `email`      VARCHAR(255)    NOT NULL,
  `token`      VARCHAR(255)    NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `password_resets_email_idx` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
--  User ↔ Branch (many-to-many)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `user_branches` (
  `user_id`    CHAR(36)        NOT NULL,
  `branch_id`  CHAR(36)        NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`user_id`, `branch_id`),
  KEY `user_branches_branch_id_foreign` (`branch_id`),
  CONSTRAINT `user_branches_user_id_foreign`
    FOREIGN KEY (`user_id`)   REFERENCES `users`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_branches_branch_id_foreign`
    FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Users can cover multiple branches.';


-- ============================================================
--  MODULE 03 · ROLES & PERMISSIONS  (Spatie — team/tenant mode)
-- ============================================================

CREATE TABLE `roles` (
  `id`              CHAR(36)        NOT NULL,
  `tenant_id`       CHAR(36)        NOT NULL COMMENT 'Roles are scoped per tenant',
  `name_en`         VARCHAR(255)    NOT NULL,
  `name_ar`         VARCHAR(255)    NOT NULL,
  `guard_name`      VARCHAR(255)    NOT NULL DEFAULT 'api',
  `display_name_en` VARCHAR(255)    DEFAULT NULL,
  `display_name_ar` VARCHAR(255)    DEFAULT NULL,
  `description_en`  VARCHAR(500)    DEFAULT NULL,
  `description_ar`  VARCHAR(500)    DEFAULT NULL,
  `is_system`    TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'System roles cannot be deleted',
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`   TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `roles_name_tenant_guard_unique` (`tenant_id`, `name_en`, `guard_name`),
  KEY `roles_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `roles_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Spatie roles scoped per tenant (team mode).';

CREATE TABLE `permissions` (
  `id`              CHAR(36)        NOT NULL,
  `tenant_id`       CHAR(36)        NOT NULL DEFAULT 'central' COMMENT "'central' = global; else tenant-specific",
  `name_en`         VARCHAR(255)    NOT NULL COMMENT 'e.g. sales.invoices.create',
  `name_ar`         VARCHAR(255)    NOT NULL,
  `guard_name`      VARCHAR(255)    NOT NULL DEFAULT 'api',
  `module`          VARCHAR(100)    DEFAULT NULL COMMENT 'sales | inventory | finance | hr',
  `display_name_en` VARCHAR(255)    DEFAULT NULL,
  `display_name_ar` VARCHAR(255)    DEFAULT NULL,
  `description_en`  VARCHAR(500)    DEFAULT NULL,
  `description_ar`  VARCHAR(500)    DEFAULT NULL,
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`   TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `permissions_name_guard_tenant_unique` (`tenant_id`, `name_en`, `guard_name`),
  KEY `permissions_tenant_id_idx` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-tenant permission definitions. tenant_id=central for global defaults.';

CREATE TABLE `role_has_permissions` (
  `id`            CHAR(36)        NOT NULL,
  `tenant_id`     CHAR(36)        NOT NULL,
  `permission_id` CHAR(36)        NOT NULL,
  `role_id`       CHAR(36)        NOT NULL,
  `created_at`    TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rhp_tenant_role_permission_unique` (`tenant_id`, `role_id`, `permission_id`),
  KEY `role_has_permissions_role_id_foreign` (`role_id`),
  CONSTRAINT `rhp_permission_id_foreign`
    FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `rhp_role_id_foreign`
    FOREIGN KEY (`role_id`)       REFERENCES `roles`       (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `model_has_roles` (
  `id`           CHAR(36)        NOT NULL,
  `role_id`      CHAR(36)        NOT NULL,
  `model_type`   VARCHAR(255)    NOT NULL,
  `model_id`     CHAR(36)        NOT NULL,
  `tenant_id`    CHAR(36)        NOT NULL,
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mhr_model_role_tenant_unique` (`model_id`, `model_type`, `role_id`, `tenant_id`),
  KEY `model_has_roles_role_id_foreign` (`role_id`),
  CONSTRAINT `mhr_role_id_foreign`
    FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `model_has_permissions` (
  `id`            CHAR(36)        NOT NULL,
  `permission_id` CHAR(36)        NOT NULL,
  `model_type`    VARCHAR(255)    NOT NULL,
  `model_id`      CHAR(36)        NOT NULL,
  `tenant_id`     CHAR(36)        NOT NULL,
  `created_at`    TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mhp_model_permission_tenant_unique` (`model_id`, `model_type`, `permission_id`, `tenant_id`),
  KEY `model_has_permissions_permission_id_foreign` (`permission_id`),
  CONSTRAINT `mhp_permission_id_foreign`
    FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
--  MODULE 04 · CONTACTS  (Customers & Suppliers)
-- ============================================================

-- FIX v2: activity_types is now per-tenant (was shared, but types are business-specific)
CREATE TABLE `activity_types` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `name_en`    VARCHAR(255)    NOT NULL,
  `name_ar`    VARCHAR(255)    NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `activity_types_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `activity_types_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Business activity types per tenant (e.g. Retail, Wholesale, Pharmacy).';

-- ─────────────────────────────────────────────────────────
CREATE TABLE `sales_segments` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `name_en`        VARCHAR(255)    NOT NULL,
  `name_ar`        VARCHAR(255)    NOT NULL,
  `description_en` VARCHAR(500)    DEFAULT NULL,
  `description_ar` VARCHAR(500)    DEFAULT NULL,
  `created_at`  TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`  TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`  TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sales_segments_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `sales_segments_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
CREATE TABLE `contacts` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `type`             TINYINT('customer','supplier') NOT NULL DEFAULT 'customer',
  -- identification
  `name_en`          VARCHAR(255)    NOT NULL,
  `name_ar`          VARCHAR(255)    NOT NULL,
  `code`             VARCHAR(50)     DEFAULT NULL,
  -- FIX v2: contact_code unique now scoped to tenant_id
  `contact_code`     VARCHAR(50)     DEFAULT NULL,
  `tax_number`       VARCHAR(100)    DEFAULT NULL,
  `national_id`      VARCHAR(50)     DEFAULT NULL,
  `contact_person`   VARCHAR(255)    DEFAULT NULL,
  -- contact info
  `phone`            VARCHAR(50)     DEFAULT NULL,
  `email`            VARCHAR(255)    DEFAULT NULL,
  `address`          TEXT            DEFAULT NULL,
  `latitude`         DECIMAL(10,7)   DEFAULT NULL,
  `longitude`        DECIMAL(10,7)   DEFAULT NULL,
  -- location FKs
  `governorate_id`   CHAR(36)        DEFAULT NULL,
  `city_id`          CHAR(36)        DEFAULT NULL,
  -- classification
  `activity_type_id` CHAR(36)        DEFAULT NULL,
  `contact_type`     VARCHAR(100)    DEFAULT NULL,
  `sales_segment_id` CHAR(36)        DEFAULT NULL,
  `assigned_to`      CHAR(36)        DEFAULT NULL COMMENT 'Sales rep user_id (CRM)',
  -- financial
  `balance`          DECIMAL(15,4)   NOT NULL DEFAULT 0.0000 COMMENT 'Denormalized cache — derived from payment_transactions',
  `opening_balance`  DECIMAL(15,4)   DEFAULT NULL,
  `credit_limit`     DECIMAL(15,4)   DEFAULT NULL,
  -- misc
  `is_active`        TINYINT(1)      NOT NULL DEFAULT 1,
  `is_default`       TINYINT(1)      NOT NULL DEFAULT 0,
  `tags`             JSON            DEFAULT NULL,
  `notes`            TEXT            DEFAULT NULL,
  `verified_at`      TIMESTAMP       NULL DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  -- contact_code scoped per tenant
  UNIQUE KEY `contacts_contact_code_tenant_unique` (`tenant_id`, `contact_code`),
  UNIQUE KEY `contacts_email_tenant_unique`         (`tenant_id`, `email`),
  KEY `contacts_tenant_type_idx`       (`tenant_id`, `type`),
  KEY `contacts_tenant_segment_idx`    (`tenant_id`, `sales_segment_id`),
  KEY `contacts_governorate_id_fk`     (`governorate_id`),
  KEY `contacts_city_id_fk`            (`city_id`),
  KEY `contacts_activity_type_id_fk`   (`activity_type_id`),
  KEY `contacts_sales_segment_id_fk`   (`sales_segment_id`),
  KEY `contacts_assigned_to_fk`        (`assigned_to`),
  CONSTRAINT `contacts_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)         REFERENCES `tenants`        (`id`) ON DELETE CASCADE,
  CONSTRAINT `contacts_governorate_id_foreign`
    FOREIGN KEY (`governorate_id`)    REFERENCES `governorates`   (`id`) ON DELETE SET NULL,
  CONSTRAINT `contacts_city_id_foreign`
    FOREIGN KEY (`city_id`)           REFERENCES `cities`         (`id`) ON DELETE SET NULL,
  CONSTRAINT `contacts_activity_type_id_foreign`
    FOREIGN KEY (`activity_type_id`)  REFERENCES `activity_types` (`id`) ON DELETE SET NULL,
  CONSTRAINT `contacts_sales_segment_id_foreign`
    FOREIGN KEY (`sales_segment_id`)  REFERENCES `sales_segments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `contacts_assigned_to_foreign`
    FOREIGN KEY (`assigned_to`)       REFERENCES `users`          (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Unified customers & suppliers.';


-- ============================================================
--  MODULE 05 · PRODUCTS & CATALOG
-- ============================================================

CREATE TABLE `brands` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `name_en`    VARCHAR(255)    NOT NULL,
  `name_ar`    VARCHAR(255)    NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `brands_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `brands_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
CREATE TABLE `categories` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `parent_id`  CHAR(36)        DEFAULT NULL COMMENT 'NULL = top-level category',
  `name_en`    VARCHAR(255)    NOT NULL,
  `name_ar`    VARCHAR(255)    NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `categories_tenant_id_idx` (`tenant_id`),
  KEY `categories_parent_id_fk`  (`parent_id`),
  CONSTRAINT `categories_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `categories_parent_id_foreign`
    FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
CREATE TABLE `units` (
  `id`                   CHAR(36)        NOT NULL,
  `tenant_id`            CHAR(36)        NOT NULL,
  `actual_name_en`       VARCHAR(255)    NOT NULL,
  `actual_name_ar`       VARCHAR(255)    NOT NULL,
  `short_name_en`        VARCHAR(50)     DEFAULT NULL,
  `short_name_ar`        VARCHAR(50)     DEFAULT NULL,
  `base_unit_id`         CHAR(36)        DEFAULT NULL COMMENT 'NULL = this IS the base unit',
  `base_unit_multiplier` DECIMAL(10,4)   DEFAULT NULL COMMENT 'e.g. 12 if 1 box = 12 units',
  `base_unit_is_largest` TINYINT(1)      NOT NULL DEFAULT 0,
  `created_at`           TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`           TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`           TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `units_tenant_id_idx`     (`tenant_id`),
  KEY `units_base_unit_id_fk`   (`base_unit_id`),
  CONSTRAINT `units_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `units_base_unit_id_foreign`
    FOREIGN KEY (`base_unit_id`) REFERENCES `units`   (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
CREATE TABLE `products` (
  `id`                  CHAR(36)        NOT NULL,
  `tenant_id`           CHAR(36)        NOT NULL,
  `name_en`             VARCHAR(255)    NOT NULL,
  `name_ar`             VARCHAR(255)    NOT NULL,
  `sku`                 VARCHAR(100)    DEFAULT NULL,
  `barcode`             VARCHAR(100)    DEFAULT NULL,
  `description_en`      TEXT            DEFAULT NULL,
  `description_ar`      TEXT            DEFAULT NULL,
  `type`             ENUM('standard','variable','service','combo') NOT NULL DEFAULT 'standard',
  -- catalog
  `unit_id`          CHAR(36)        DEFAULT NULL COMMENT 'Base/default unit',
  `brand_id`         CHAR(36)        DEFAULT NULL,
  `category_id`      CHAR(36)        DEFAULT NULL COMMENT 'Sub-category',
  `main_category_id` CHAR(36)        DEFAULT NULL COMMENT 'Main/parent category',
  -- pricing
  `unit_price`       DECIMAL(15,4)   NOT NULL DEFAULT 0.0000 COMMENT 'Default sale price in base unit',
  `purchase_price`   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_rate`         DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
  -- stock settings
  `enable_stock`     TINYINT(1)      NOT NULL DEFAULT 1,
  `quantity_alert`   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `min_sale`         DECIMAL(15,4)   DEFAULT NULL,
  `max_sale`         DECIMAL(15,4)   DEFAULT NULL,
  `for_sale`         TINYINT(1)      NOT NULL DEFAULT 1,
  `is_serialized`    TINYINT(1)      NOT NULL DEFAULT 0,
  `has_expiry`       TINYINT(1)      NOT NULL DEFAULT 0,
  -- meta
  `notes`            TEXT            DEFAULT NULL,
  `created_by`       CHAR(36)        DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `products_tenant_id_idx`        (`tenant_id`),
  KEY `products_tenant_sku_idx`       (`tenant_id`, `sku`),
  KEY `products_tenant_barcode_idx`   (`tenant_id`, `barcode`),
  KEY `products_unit_id_fk`           (`unit_id`),
  KEY `products_brand_id_fk`          (`brand_id`),
  KEY `products_category_id_fk`       (`category_id`),
  KEY `products_main_category_id_fk`  (`main_category_id`),
  KEY `products_created_by_fk`        (`created_by`),
  CONSTRAINT `products_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)        REFERENCES `tenants`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `products_unit_id_foreign`
    FOREIGN KEY (`unit_id`)          REFERENCES `units`      (`id`) ON DELETE SET NULL,
  CONSTRAINT `products_brand_id_foreign`
    FOREIGN KEY (`brand_id`)         REFERENCES `brands`     (`id`) ON DELETE SET NULL,
  CONSTRAINT `products_category_id_foreign`
    FOREIGN KEY (`category_id`)      REFERENCES `categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `products_main_category_id_foreign`
    FOREIGN KEY (`main_category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `products_created_by_foreign`
    FOREIGN KEY (`created_by`)       REFERENCES `users`      (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
--  Per-unit pricing per product
-- ─────────────────────────────────────────────────────────
CREATE TABLE `product_unit_details` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `product_id`     CHAR(36)        NOT NULL,
  `unit_id`        CHAR(36)        NOT NULL,
  `sale_price`     DECIMAL(15,4)   NOT NULL,
  `purchase_price` DECIMAL(15,4)   NOT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pud_product_unit_unique` (`tenant_id`, `product_id`, `unit_id`),
  KEY `pud_product_id_fk` (`product_id`),
  KEY `pud_unit_id_fk`    (`unit_id`),
  CONSTRAINT `pud_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `pud_product_id_foreign`
    FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pud_unit_id_foreign`
    FOREIGN KEY (`unit_id`)    REFERENCES `units`    (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
--  Price change audit log per product+unit
-- ─────────────────────────────────────────────────────────
CREATE TABLE `product_price_histories` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `product_id`     CHAR(36)        NOT NULL,
  `unit_id`        CHAR(36)        NOT NULL,
  `old_unit_price` DECIMAL(15,4)   NOT NULL,
  `new_unit_price` DECIMAL(15,4)   NOT NULL,
  `changed_by`     CHAR(36)        NOT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `pph_tenant_product_idx` (`tenant_id`, `product_id`),
  KEY `pph_product_id_fk`      (`product_id`),
  KEY `pph_unit_id_fk`         (`unit_id`),
  KEY `pph_changed_by_fk`      (`changed_by`),
  CONSTRAINT `pph_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `pph_product_id_foreign`
    FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pph_unit_id_foreign`
    FOREIGN KEY (`unit_id`)    REFERENCES `units`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `pph_changed_by_foreign`
    FOREIGN KEY (`changed_by`) REFERENCES `users`    (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
--  Segment-specific product pricing
-- ─────────────────────────────────────────────────────────
CREATE TABLE `sales_segment_products` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `sales_segment_id` CHAR(36)        NOT NULL,
  `product_id`       CHAR(36)        NOT NULL,
  `unit_id`          CHAR(36)        NOT NULL,
  `price`            DECIMAL(15,4)   NOT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ssp_segment_product_unit_unique` (`tenant_id`, `sales_segment_id`, `product_id`, `unit_id`),
  KEY `ssp_sales_segment_id_fk` (`sales_segment_id`),
  KEY `ssp_product_id_fk`       (`product_id`),
  KEY `ssp_unit_id_fk`          (`unit_id`),
  CONSTRAINT `ssp_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)        REFERENCES `tenants`       (`id`) ON DELETE CASCADE,
  CONSTRAINT `ssp_sales_segment_id_foreign`
    FOREIGN KEY (`sales_segment_id`) REFERENCES `sales_segments`(`id`) ON DELETE CASCADE,
  CONSTRAINT `ssp_product_id_foreign`
    FOREIGN KEY (`product_id`)       REFERENCES `products`      (`id`) ON DELETE CASCADE,
  CONSTRAINT `ssp_unit_id_foreign`
    FOREIGN KEY (`unit_id`)          REFERENCES `units`         (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
--  NEW: Serial numbers per product item (for is_serialized products)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `serial_numbers` (
  `id`           CHAR(36)        NOT NULL,
  `tenant_id`    CHAR(36)        NOT NULL,
  `product_id`   CHAR(36)        NOT NULL,
  `warehouse_id` CHAR(36)        DEFAULT NULL,
  `serial_no`    VARCHAR(100)    NOT NULL,
  `status`       ENUM('available','sold','returned','defective') NOT NULL DEFAULT 'available',
  `sold_in_transaction_id` CHAR(36) DEFAULT NULL COMMENT 'sale transaction that consumed this serial',
  `notes`        TEXT            DEFAULT NULL,
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`   TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `serial_numbers_tenant_serial_unique` (`tenant_id`, `serial_no`),
  KEY `sn_tenant_product_idx`  (`tenant_id`, `product_id`),
  KEY `sn_warehouse_id_fk`     (`warehouse_id`),
  CONSTRAINT `sn_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)   REFERENCES `tenants`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `sn_product_id_foreign`
    FOREIGN KEY (`product_id`)  REFERENCES `products`   (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Serial numbers for is_serialized products. One row per physical unit.';

-- ─────────────────────────────────────────────────────────
--  NEW: Batch / lot numbers (for has_expiry products)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `batch_numbers` (
  `id`            CHAR(36)        NOT NULL,
  `tenant_id`     CHAR(36)        NOT NULL,
  `product_id`    CHAR(36)        NOT NULL,
  `warehouse_id`  CHAR(36)        DEFAULT NULL,
  `batch_no`      VARCHAR(100)    NOT NULL,
  `expiry_date`   DATE            DEFAULT NULL,
  `manufacture_date` DATE         DEFAULT NULL,
  `qty_received`  DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `qty_remaining` DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `unit_cost`     DECIMAL(15,4)   DEFAULT NULL,
  `notes`         TEXT            DEFAULT NULL,
  `created_at`    TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `batch_numbers_tenant_batch_unique` (`tenant_id`, `product_id`, `batch_no`),
  KEY `bn_tenant_product_idx`  (`tenant_id`, `product_id`),
  KEY `bn_expiry_idx`          (`tenant_id`, `expiry_date`),
  KEY `bn_warehouse_id_fk`     (`warehouse_id`),
  CONSTRAINT `bn_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `bn_product_id_foreign`
    FOREIGN KEY (`product_id`)   REFERENCES `products`   (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Batch/lot tracking for has_expiry products. Supports FEFO inventory.';

-- ─────────────────────────────────────────────────────────
--  Media — Custom Media Module (replaces Spatie Medialibrary)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `media_files` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `model_type`     VARCHAR(255)    NOT NULL,
  `model_id`       CHAR(36)        NOT NULL,
  `collection`     VARCHAR(100)    NOT NULL DEFAULT 'default',
  `file_name`      VARCHAR(255)    NOT NULL,
  `original_name`  VARCHAR(255)    NOT NULL,
  `mime_type`      VARCHAR(100)    DEFAULT NULL,
  `disk`           VARCHAR(50)     NOT NULL DEFAULT 'public',
  `file_path`      VARCHAR(500)    NOT NULL,
  `file_size`      BIGINT UNSIGNED NOT NULL,
  `order`          INT UNSIGNED    DEFAULT 0,
  `created_by`     CHAR(36)        DEFAULT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `media_files_tenant_model_idx` (`tenant_id`, `model_type`, `model_id`),
  KEY `media_files_collection_idx`   (`tenant_id`, `collection`),
  KEY `media_files_created_by_fk`    (`created_by`),
  CONSTRAINT `mf_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `mf_created_by_foreign`
    FOREIGN KEY (`created_by`) REFERENCES `users`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Custom Media Module — polymorphic file attachments per tenant.';


-- ============================================================
--  MODULE 06 · FINANCE & ACCOUNTS
-- ============================================================

CREATE TABLE `account_types` (
  `id`             CHAR(36)        NOT NULL,
  `name_en`        VARCHAR(100)    NOT NULL COMMENT 'Asset | Liability | Equity | Revenue | Expense',
  `name_ar`        VARCHAR(100)    NOT NULL,
  `normal_balance` ENUM('debit','credit') NOT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Double-entry account type definitions. Seeded, not per-tenant.';

-- ─────────────────────────────────────────────────────────
CREATE TABLE `accounts` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `name_en`    VARCHAR(255)    NOT NULL,
  `name_ar`    VARCHAR(255)    NOT NULL,
  `number`     VARCHAR(100)    DEFAULT NULL,
  `balance`    DECIMAL(15,4)   NOT NULL DEFAULT 0.0000 COMMENT 'Running balance cache',
  `is_active`  TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `accounts_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `accounts_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Cash drawers and bank accounts per tenant.';

-- Add deferred FKs on branches → accounts (accounts created after branches)
ALTER TABLE `branches`
  ADD CONSTRAINT `branches_cash_account_id_foreign`
    FOREIGN KEY (`cash_account_id`)   REFERENCES `accounts` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `branches_credit_account_id_foreign`
    FOREIGN KEY (`credit_account_id`) REFERENCES `accounts` (`id`) ON DELETE SET NULL;

-- ─────────────────────────────────────────────────────────
CREATE TABLE `chart_of_accounts` (
  `id`              CHAR(36)        NOT NULL,
  `tenant_id`       CHAR(36)        NOT NULL,
  `parent_id`       CHAR(36)        DEFAULT NULL,
  `account_type_id` CHAR(36)        NOT NULL,
  `code`            VARCHAR(50)     NOT NULL,
  `name_en`         VARCHAR(255)    NOT NULL,
  `name_ar`         VARCHAR(255)    NOT NULL,
  `description_en`  TEXT            DEFAULT NULL,
  `description_ar`  TEXT            DEFAULT NULL,
  `currency`        VARCHAR(10)     NOT NULL DEFAULT 'EGP',
  `is_system`       TINYINT(1)      NOT NULL DEFAULT 0,
  `is_active`       TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`      TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`      TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `coa_code_tenant_unique` (`tenant_id`, `code`),
  KEY `coa_tenant_id_idx`        (`tenant_id`),
  KEY `coa_parent_id_fk`         (`parent_id`),
  KEY `coa_account_type_id_fk`   (`account_type_id`),
  CONSTRAINT `coa_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)       REFERENCES `tenants`          (`id`) ON DELETE CASCADE,
  CONSTRAINT `coa_parent_id_foreign`
    FOREIGN KEY (`parent_id`)       REFERENCES `chart_of_accounts`(`id`) ON DELETE CASCADE,
  CONSTRAINT `coa_account_type_id_foreign`
    FOREIGN KEY (`account_type_id`) REFERENCES `account_types`    (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
CREATE TABLE `journal_entries` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `entry_number`   VARCHAR(100)    DEFAULT NULL,
  `entry_date`     DATE            NOT NULL,
  `reference_type` VARCHAR(100)    DEFAULT NULL COMMENT 'sales_transaction | purchase_transaction | inventory_transaction | payment | expense',
  `reference_id`   CHAR(36)        DEFAULT NULL,
  `description`    TEXT            DEFAULT NULL,
  `is_posted`      TINYINT(1)      NOT NULL DEFAULT 0,
  `posted_at`      TIMESTAMP       NULL DEFAULT NULL,
  `posted_by`      CHAR(36)        DEFAULT NULL,
  `created_by`     CHAR(36)        NOT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `je_tenant_date_idx`  (`tenant_id`, `entry_date`),
  KEY `je_reference_idx`    (`reference_type`, `reference_id`),
  KEY `je_posted_by_fk`     (`posted_by`),
  KEY `je_created_by_fk`    (`created_by`),
  CONSTRAINT `je_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `je_posted_by_foreign`
    FOREIGN KEY (`posted_by`)  REFERENCES `users`   (`id`) ON DELETE SET NULL,
  CONSTRAINT `je_created_by_foreign`
    FOREIGN KEY (`created_by`) REFERENCES `users`   (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `journal_entry_lines` (
  `id`               CHAR(36)        NOT NULL,
  `journal_entry_id` CHAR(36)        NOT NULL,
  `account_id`       CHAR(36)        NOT NULL,
  `debit`            DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `credit`           DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `description`      VARCHAR(500)    DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `jel_journal_entry_id_fk` (`journal_entry_id`),
  KEY `jel_account_id_fk`       (`account_id`),
  CONSTRAINT `jel_journal_entry_id_foreign`
    FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries`   (`id`) ON DELETE CASCADE,
  CONSTRAINT `jel_account_id_foreign`
    FOREIGN KEY (`account_id`)       REFERENCES `chart_of_accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
CREATE TABLE `taxes` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `name_en`    VARCHAR(100)    NOT NULL COMMENT 'e.g. VAT 14%, Withholding 5%',
  `name_ar`    VARCHAR(100)    NOT NULL,
  `rate`       DECIMAL(5,2)    NOT NULL,
  `type`       ENUM('percentage','fixed') NOT NULL DEFAULT 'percentage',
  `is_active`  TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `taxes_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `taxes_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
CREATE TABLE `cost_centers` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `parent_id`  CHAR(36)        DEFAULT NULL,
  `name_en`    VARCHAR(255)    NOT NULL,
  `name_ar`    VARCHAR(255)    NOT NULL,
  `code`       VARCHAR(50)     DEFAULT NULL,
  `is_active`  TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cost_centers_tenant_id_idx` (`tenant_id`),
  KEY `cost_centers_parent_id_fk`  (`parent_id`),
  CONSTRAINT `cost_centers_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants`      (`id`) ON DELETE CASCADE,
  CONSTRAINT `cost_centers_parent_id_foreign`
    FOREIGN KEY (`parent_id`) REFERENCES `cost_centers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
CREATE TABLE `expense_categories` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `name_en`    VARCHAR(255)    NOT NULL,
  `name_ar`    VARCHAR(255)    NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `expense_categories_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `expense_categories_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `expenses` (
  `id`                  CHAR(36)        NOT NULL,
  `tenant_id`           CHAR(36)        NOT NULL,
  `expense_category_id` CHAR(36)        NOT NULL,
  `account_id`          CHAR(36)        NOT NULL,
  `branch_id`           CHAR(36)        NOT NULL,
  `cost_center_id`      CHAR(36)        DEFAULT NULL,
  `amount`              DECIMAL(15,4)   NOT NULL,
  `expense_date`        DATE            DEFAULT NULL,
  `note`                VARCHAR(500)    DEFAULT NULL,
  `created_by`          CHAR(36)        DEFAULT NULL,
  `created_at`          TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`          TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `expenses_tenant_id_idx`           (`tenant_id`),
  KEY `expenses_expense_category_id_fk`  (`expense_category_id`),
  KEY `expenses_account_id_fk`           (`account_id`),
  KEY `expenses_branch_id_fk`            (`branch_id`),
  KEY `expenses_cost_center_id_fk`       (`cost_center_id`),
  KEY `expenses_created_by_fk`           (`created_by`),
  CONSTRAINT `expenses_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)           REFERENCES `tenants`           (`id`) ON DELETE CASCADE,
  CONSTRAINT `expenses_category_id_foreign`
    FOREIGN KEY (`expense_category_id`) REFERENCES `expense_categories`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `expenses_account_id_foreign`
    FOREIGN KEY (`account_id`)          REFERENCES `accounts`          (`id`) ON DELETE RESTRICT,
  CONSTRAINT `expenses_branch_id_foreign`
    FOREIGN KEY (`branch_id`)           REFERENCES `branches`          (`id`) ON DELETE RESTRICT,
  CONSTRAINT `expenses_cost_center_id_foreign`
    FOREIGN KEY (`cost_center_id`)      REFERENCES `cost_centers`      (`id`) ON DELETE SET NULL,
  CONSTRAINT `expenses_created_by_foreign`
    FOREIGN KEY (`created_by`)          REFERENCES `users`             (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
--  MODULE 07 · INVENTORY
-- ============================================================

CREATE TABLE `warehouses` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `branch_id`  CHAR(36)        DEFAULT NULL,
  `name_en`    VARCHAR(255)    NOT NULL,
  `name_ar`    VARCHAR(255)    NOT NULL,
  `code`       VARCHAR(50)     DEFAULT NULL,
  `address`    TEXT            DEFAULT NULL,
  `is_active`  TINYINT(1)      NOT NULL DEFAULT 1,
  `is_default` TINYINT(1)      NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `warehouses_tenant_id_idx` (`tenant_id`),
  KEY `warehouses_branch_id_fk`  (`branch_id`),
  CONSTRAINT `warehouses_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `warehouses_branch_id_foreign`
    FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
--  Now that warehouses exists, add the deferred FKs in serial_numbers
--  and batch_numbers (defined earlier before warehouses)
-- ─────────────────────────────────────────────────────────

ALTER TABLE `serial_numbers`
  ADD CONSTRAINT `sn_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE SET NULL;

ALTER TABLE `batch_numbers`
  ADD CONSTRAINT `bn_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE SET NULL;

-- ─────────────────────────────────────────────────────────
CREATE TABLE `stock_levels` (
  `id`            CHAR(36)        NOT NULL,
  `tenant_id`     CHAR(36)        NOT NULL,
  `warehouse_id`  CHAR(36)        NOT NULL,
  `product_id`    CHAR(36)        NOT NULL,
  `unit_id`       CHAR(36)        NOT NULL,
  `qty_available` DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `qty_reserved`  DECIMAL(15,4)   NOT NULL DEFAULT 0.0000 COMMENT 'Reserved by pending orders',
  `qty_on_order`  DECIMAL(15,4)   NOT NULL DEFAULT 0.0000 COMMENT 'In open purchase orders',
  `updated_at`    TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `stock_levels_unique` (`tenant_id`, `warehouse_id`, `product_id`, `unit_id`),
  KEY `stock_levels_tenant_product_idx` (`tenant_id`, `product_id`),
  KEY `stock_levels_warehouse_id_fk`   (`warehouse_id`),
  KEY `stock_levels_product_id_fk`     (`product_id`),
  KEY `stock_levels_unit_id_fk`        (`unit_id`),
  CONSTRAINT `sl_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `sl_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sl_product_id_foreign`
    FOREIGN KEY (`product_id`)   REFERENCES `products`   (`id`) ON DELETE CASCADE,
  CONSTRAINT `sl_unit_id_foreign`
    FOREIGN KEY (`unit_id`)      REFERENCES `units`      (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Real-time stock snapshot per warehouse/product/unit.';

-- ─────────────────────────────────────────────────────────
CREATE TABLE `stock_movements` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `warehouse_id`   CHAR(36)        NOT NULL,
  `product_id`     CHAR(36)        NOT NULL,
  `unit_id`        CHAR(36)        NOT NULL,
  -- reference can point to any of the three transaction tables
  `reference_type` VARCHAR(50)     DEFAULT NULL
    COMMENT 'sales_transaction | purchase_transaction | inventory_transaction',
  `reference_id`   CHAR(36)        DEFAULT NULL,
  `movement_type`  VARCHAR(30)     NOT NULL
    COMMENT 'purchase | sale | sale_return | purchase_return | transfer_in | transfer_out | adjustment | opening_stock | spoilage',
  `quantity`       DECIMAL(15,4)   NOT NULL COMMENT 'Positive = in, Negative = out',
  `unit_cost`      DECIMAL(15,4)   DEFAULT NULL,
  `reference_no`   VARCHAR(100)    DEFAULT NULL,
  `batch_id`       CHAR(36)        DEFAULT NULL COMMENT 'Linked batch_number row if applicable',
  `serial_id`      CHAR(36)        DEFAULT NULL COMMENT 'Linked serial_number row if applicable',
  `note`           TEXT            DEFAULT NULL,
  `created_by`     CHAR(36)        DEFAULT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sm_tenant_product_idx` (`tenant_id`, `product_id`),
  KEY `sm_tenant_date_idx`    (`tenant_id`, `created_at`),
  KEY `sm_reference_idx`      (`reference_type`, `reference_id`),
  KEY `sm_warehouse_id_fk`    (`warehouse_id`),
  KEY `sm_created_by_fk`      (`created_by`),
  KEY `sm_batch_id_fk`        (`batch_id`),
  KEY `sm_serial_id_fk`       (`serial_id`),
  CONSTRAINT `sm_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants`        (`id`) ON DELETE CASCADE,
  CONSTRAINT `sm_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses`     (`id`) ON DELETE CASCADE,
  CONSTRAINT `sm_product_id_foreign`
    FOREIGN KEY (`product_id`)   REFERENCES `products`       (`id`) ON DELETE CASCADE,
  CONSTRAINT `sm_unit_id_foreign`
    FOREIGN KEY (`unit_id`)      REFERENCES `units`          (`id`) ON DELETE CASCADE,
  CONSTRAINT `sm_created_by_foreign`
    FOREIGN KEY (`created_by`)   REFERENCES `users`          (`id`) ON DELETE SET NULL,
  CONSTRAINT `sm_batch_id_foreign`
    FOREIGN KEY (`batch_id`)     REFERENCES `batch_numbers`  (`id`) ON DELETE SET NULL,
  CONSTRAINT `sm_serial_id_foreign`
    FOREIGN KEY (`serial_id`)    REFERENCES `serial_numbers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Append-only stock ledger. Never update or delete rows.';

-- ─────────────────────────────────────────────────────────
CREATE TABLE `stock_adjustments` (
  `id`           CHAR(36)        NOT NULL,
  `tenant_id`    CHAR(36)        NOT NULL,
  `warehouse_id` CHAR(36)        NOT NULL,
  `ref_no`       VARCHAR(100)    DEFAULT NULL,
  `reason`       VARCHAR(500)    DEFAULT NULL,
  `status`       ENUM('draft','approved','rejected') NOT NULL DEFAULT 'draft',
  `approved_by`  CHAR(36)        DEFAULT NULL,
  `approved_at`  TIMESTAMP       NULL DEFAULT NULL,
  `created_by`   CHAR(36)        NOT NULL,
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`   TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sa_tenant_id_idx`     (`tenant_id`),
  KEY `sa_warehouse_id_fk`   (`warehouse_id`),
  KEY `sa_approved_by_fk`    (`approved_by`),
  KEY `sa_created_by_fk`     (`created_by`),
  CONSTRAINT `sa_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `sa_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sa_approved_by_foreign`
    FOREIGN KEY (`approved_by`)  REFERENCES `users`      (`id`) ON DELETE SET NULL,
  CONSTRAINT `sa_created_by_foreign`
    FOREIGN KEY (`created_by`)   REFERENCES `users`      (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `stock_adjustment_lines` (
  `id`                  CHAR(36)        NOT NULL,
  `stock_adjustment_id` CHAR(36)        NOT NULL,
  `product_id`          CHAR(36)        NOT NULL,
  `unit_id`             CHAR(36)        NOT NULL,
  `qty_system`          DECIMAL(15,4)   NOT NULL COMMENT 'What the system recorded',
  `qty_actual`          DECIMAL(15,4)   NOT NULL COMMENT 'What was physically counted',
  `deleted_at`          TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sal_stock_adjustment_id_fk` (`stock_adjustment_id`),
  KEY `sal_product_id_fk`          (`product_id`),
  CONSTRAINT `sal_adjustment_id_foreign`
    FOREIGN KEY (`stock_adjustment_id`) REFERENCES `stock_adjustments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sal_product_id_foreign`
    FOREIGN KEY (`product_id`)          REFERENCES `products`          (`id`) ON DELETE CASCADE,
  CONSTRAINT `sal_unit_id_foreign`
    FOREIGN KEY (`unit_id`)             REFERENCES `units`             (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
--  MODULE 08 · TRANSACTIONS
--  Replaces single `transactions` table with three purpose-built tables:
--
--    sales_transactions      → type: sell | sell_return
--    purchase_transactions   → type: purchase | purchase_return
--    inventory_transactions  → type: transfer | opening_stock | spoiled_stock | adjustment
--
--  Benefits:
--    - Each table has only the columns relevant to its domain
--    - No NULLable columns that only apply to one type
--    - FKs can be enforced correctly per domain
--    - Query performance: no type-filtering on a single giant table
-- ============================================================

-- ─────────────────────────────────────────────────────────
--  8A. SALES TRANSACTIONS  (invoices & sales returns)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `sales_transactions` (
  `id`                    CHAR(36)        NOT NULL,
  `tenant_id`             CHAR(36)        NOT NULL,
  `branch_id`             CHAR(36)        DEFAULT NULL,
  `warehouse_id`          CHAR(36)        DEFAULT NULL,
  `contact_id`            CHAR(36)        DEFAULT NULL COMMENT 'Customer',
  `tax_id`                CHAR(36)        DEFAULT NULL,
  `created_by`            CHAR(36)        DEFAULT NULL,
  `return_of_id`          CHAR(36)        DEFAULT NULL COMMENT 'Original sales_transaction for returns',
  -- classification
  `type`                  ENUM('sell','sell_return') NOT NULL DEFAULT 'sell',
  `status`                ENUM('draft','confirmed','cancelled') NOT NULL DEFAULT 'draft',
  `ref_no`                VARCHAR(100)    DEFAULT NULL,
  `transaction_date`      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- amounts
  `subtotal`              DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `discount_type`         ENUM('percentage','fixed_price') DEFAULT NULL,
  `discount_value`        DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_amount`            DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `shipping_cost`         DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `final_price`           DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  -- payment
  `payment_type`          ENUM('cash','credit') NOT NULL DEFAULT 'cash',
  `payment_status`        ENUM('due','partial','paid') NOT NULL DEFAULT 'due',
  -- delivery
  `delivery_status`       ENUM('ordered','shipped','delivered') NOT NULL DEFAULT 'ordered',
  `delivery_status_note`  VARCHAR(255)    DEFAULT NULL,
  -- meta
  `transaction_from`      VARCHAR(100)    DEFAULT NULL COMMENT 'pos | online | api',
  `notes`                 TEXT            DEFAULT NULL,
  `created_at`            TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`            TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `stx_tenant_type_idx`      (`tenant_id`, `type`),
  KEY `stx_tenant_date_idx`      (`tenant_id`, `transaction_date`),
  KEY `stx_tenant_status_idx`    (`tenant_id`, `status`),
  KEY `stx_tenant_contact_idx`   (`tenant_id`, `contact_id`),
  KEY `stx_branch_id_fk`         (`branch_id`),
  KEY `stx_warehouse_id_fk`      (`warehouse_id`),
  KEY `stx_contact_id_fk`        (`contact_id`),
  KEY `stx_return_of_id_fk`      (`return_of_id`),
  KEY `stx_created_by_fk`        (`created_by`),
  KEY `stx_tax_id_fk`            (`tax_id`),
  CONSTRAINT `stx_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants`             (`id`) ON DELETE CASCADE,
  CONSTRAINT `stx_branch_id_foreign`
    FOREIGN KEY (`branch_id`)    REFERENCES `branches`            (`id`) ON DELETE SET NULL,
  CONSTRAINT `stx_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses`          (`id`) ON DELETE SET NULL,
  CONSTRAINT `stx_contact_id_foreign`
    FOREIGN KEY (`contact_id`)   REFERENCES `contacts`            (`id`) ON DELETE SET NULL,
  CONSTRAINT `stx_return_of_id_foreign`
    FOREIGN KEY (`return_of_id`) REFERENCES `sales_transactions`  (`id`) ON DELETE SET NULL,
  CONSTRAINT `stx_created_by_foreign`
    FOREIGN KEY (`created_by`)   REFERENCES `users`               (`id`) ON DELETE SET NULL,
  CONSTRAINT `stx_tax_id_foreign`
    FOREIGN KEY (`tax_id`)       REFERENCES `taxes`               (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Sales invoices and sales returns. Separated from purchase and inventory transactions.';

CREATE TABLE `sales_transaction_lines` (
  `id`                          CHAR(36)        NOT NULL,
  `tenant_id`                   CHAR(36)        NOT NULL,
  `sales_transaction_id`        CHAR(36)        NOT NULL,
  `product_id`                  CHAR(36)        NOT NULL,
  `unit_id`                     CHAR(36)        NOT NULL,
  -- FIFO costing link: which purchase line supplied this stock
  `purchase_transaction_line_id` CHAR(36)       DEFAULT NULL,
  `batch_id`                    CHAR(36)        DEFAULT NULL,
  `serial_id`                   CHAR(36)        DEFAULT NULL,
  `quantity`                    DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `main_unit_quantity`          DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `return_quantity`             DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `unit_price`                  DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `discount`                    DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_rate`                    DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
  `total`                       DECIMAL(15,4)   DEFAULT NULL COMMENT 'Stored computed: qty * price - discount',
  `created_at`                  TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`                  TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`                  TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `stxl_tenant_id_idx`                     (`tenant_id`),
  KEY `stxl_sales_transaction_id_fk`           (`sales_transaction_id`),
  KEY `stxl_product_id_fk`                     (`product_id`),
  KEY `stxl_unit_id_fk`                        (`unit_id`),
  KEY `stxl_purchase_transaction_line_id_fk`   (`purchase_transaction_line_id`),
  KEY `stxl_batch_id_fk`                       (`batch_id`),
  KEY `stxl_serial_id_fk`                      (`serial_id`),
  CONSTRAINT `stxl_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)            REFERENCES `tenants`           (`id`) ON DELETE CASCADE,
  CONSTRAINT `stxl_sales_transaction_id_foreign`
    FOREIGN KEY (`sales_transaction_id`) REFERENCES `sales_transactions`(`id`) ON DELETE CASCADE,
  CONSTRAINT `stxl_product_id_foreign`
    FOREIGN KEY (`product_id`)           REFERENCES `products`          (`id`) ON DELETE CASCADE,
  CONSTRAINT `stxl_unit_id_foreign`
    FOREIGN KEY (`unit_id`)              REFERENCES `units`             (`id`) ON DELETE CASCADE,
  CONSTRAINT `stxl_batch_id_foreign`
    FOREIGN KEY (`batch_id`)             REFERENCES `batch_numbers`     (`id`) ON DELETE SET NULL,
  CONSTRAINT `stxl_serial_id_foreign`
    FOREIGN KEY (`serial_id`)            REFERENCES `serial_numbers`    (`id`) ON DELETE SET NULL
  -- purchase_transaction_line_id FK added after purchase_transaction_lines exists (deferred below)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Line items for sales_transactions.';

-- ─────────────────────────────────────────────────────────
--  8B. PURCHASE TRANSACTIONS  (supplier invoices & purchase returns)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `purchase_transactions` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `branch_id`        CHAR(36)        DEFAULT NULL,
  `warehouse_id`     CHAR(36)        DEFAULT NULL,
  `contact_id`       CHAR(36)        DEFAULT NULL COMMENT 'Supplier',
  `tax_id`           CHAR(36)        DEFAULT NULL,
  `purchase_order_id` CHAR(36)       DEFAULT NULL COMMENT 'Linked PO if received against a PO',
  `created_by`       CHAR(36)        DEFAULT NULL,
  `return_of_id`     CHAR(36)        DEFAULT NULL COMMENT 'Original purchase_transaction for returns',
  -- classification
  `type`             ENUM('purchase','purchase_return') NOT NULL DEFAULT 'purchase',
  `status`           ENUM('draft','confirmed','cancelled') NOT NULL DEFAULT 'draft',
  `ref_no`           VARCHAR(100)    DEFAULT NULL,
  `supplier_ref_no`  VARCHAR(100)    DEFAULT NULL COMMENT 'Supplier invoice/reference number',
  `transaction_date` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- amounts
  `subtotal`         DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `discount_type`    ENUM('percentage','fixed_price') DEFAULT NULL,
  `discount_value`   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_amount`       DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `shipping_cost`    DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `final_price`      DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  -- payment
  `payment_type`     ENUM('cash','credit') NOT NULL DEFAULT 'cash',
  `payment_status`   ENUM('due','partial','paid') NOT NULL DEFAULT 'due',
  -- meta
  `notes`            TEXT            DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ptx_tenant_type_idx`      (`tenant_id`, `type`),
  KEY `ptx_tenant_date_idx`      (`tenant_id`, `transaction_date`),
  KEY `ptx_tenant_status_idx`    (`tenant_id`, `status`),
  KEY `ptx_tenant_contact_idx`   (`tenant_id`, `contact_id`),
  KEY `ptx_branch_id_fk`         (`branch_id`),
  KEY `ptx_warehouse_id_fk`      (`warehouse_id`),
  KEY `ptx_contact_id_fk`        (`contact_id`),
  KEY `ptx_return_of_id_fk`      (`return_of_id`),
  KEY `ptx_purchase_order_id_fk` (`purchase_order_id`),
  KEY `ptx_created_by_fk`        (`created_by`),
  KEY `ptx_tax_id_fk`            (`tax_id`),
  CONSTRAINT `ptx_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)       REFERENCES `tenants`              (`id`) ON DELETE CASCADE,
  CONSTRAINT `ptx_branch_id_foreign`
    FOREIGN KEY (`branch_id`)       REFERENCES `branches`             (`id`) ON DELETE SET NULL,
  CONSTRAINT `ptx_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`)    REFERENCES `warehouses`           (`id`) ON DELETE SET NULL,
  CONSTRAINT `ptx_contact_id_foreign`
    FOREIGN KEY (`contact_id`)      REFERENCES `contacts`             (`id`) ON DELETE SET NULL,
  CONSTRAINT `ptx_return_of_id_foreign`
    FOREIGN KEY (`return_of_id`)    REFERENCES `purchase_transactions`(`id`) ON DELETE SET NULL,
  CONSTRAINT `ptx_created_by_foreign`
    FOREIGN KEY (`created_by`)      REFERENCES `users`                (`id`) ON DELETE SET NULL,
  CONSTRAINT `ptx_tax_id_foreign`
    FOREIGN KEY (`tax_id`)          REFERENCES `taxes`                (`id`) ON DELETE SET NULL
  -- purchase_order_id FK added after purchase_orders exists (deferred below)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Purchase invoices from suppliers and purchase returns.';

CREATE TABLE `purchase_transaction_lines` (
  `id`                     CHAR(36)        NOT NULL,
  `tenant_id`              CHAR(36)        NOT NULL,
  `purchase_transaction_id` CHAR(36)       NOT NULL,
  `product_id`             CHAR(36)        NOT NULL,
  `unit_id`                CHAR(36)        NOT NULL,
  `batch_id`               CHAR(36)        DEFAULT NULL,
  `quantity`               DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `main_unit_quantity`     DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `return_quantity`        DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `unit_price`             DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `discount`               DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_rate`               DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
  `total`                  DECIMAL(15,4)   DEFAULT NULL,
  `created_at`             TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`             TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`             TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ptxl_tenant_id_idx`                  (`tenant_id`),
  KEY `ptxl_purchase_transaction_id_fk`     (`purchase_transaction_id`),
  KEY `ptxl_product_id_fk`                  (`product_id`),
  KEY `ptxl_unit_id_fk`                     (`unit_id`),
  KEY `ptxl_batch_id_fk`                    (`batch_id`),
  CONSTRAINT `ptxl_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)               REFERENCES `tenants`               (`id`) ON DELETE CASCADE,
  CONSTRAINT `ptxl_purchase_transaction_id_foreign`
    FOREIGN KEY (`purchase_transaction_id`) REFERENCES `purchase_transactions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ptxl_product_id_foreign`
    FOREIGN KEY (`product_id`)              REFERENCES `products`              (`id`) ON DELETE CASCADE,
  CONSTRAINT `ptxl_unit_id_foreign`
    FOREIGN KEY (`unit_id`)                 REFERENCES `units`                 (`id`) ON DELETE CASCADE,
  CONSTRAINT `ptxl_batch_id_foreign`
    FOREIGN KEY (`batch_id`)                REFERENCES `batch_numbers`         (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Line items for purchase_transactions.';

-- Add deferred circular FK: sales_transaction_lines → purchase_transaction_lines (FIFO costing)
ALTER TABLE `sales_transaction_lines`
  ADD CONSTRAINT `stxl_purchase_transaction_line_id_foreign`
    FOREIGN KEY (`purchase_transaction_line_id`)
      REFERENCES `purchase_transaction_lines` (`id`) ON DELETE SET NULL;

-- ─────────────────────────────────────────────────────────
--  8C. INVENTORY TRANSACTIONS  (transfers, opening stock, spoilage)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `inventory_transactions` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `branch_id`        CHAR(36)        DEFAULT NULL,
  `warehouse_id`     CHAR(36)        DEFAULT NULL COMMENT 'Source warehouse',
  `warehouse_to_id`  CHAR(36)        DEFAULT NULL COMMENT 'Destination warehouse (transfers only)',
  `branch_to_id`     CHAR(36)        DEFAULT NULL COMMENT 'Destination branch (transfers only)',
  `created_by`       CHAR(36)        DEFAULT NULL,
  -- classification
  `type`             ENUM('transfer','opening_stock','spoiled_stock','adjustment') NOT NULL,
  `status`           ENUM('draft','confirmed','cancelled') NOT NULL DEFAULT 'draft',
  `ref_no`           VARCHAR(100)    DEFAULT NULL,
  `transaction_date` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- meta
  `reason`           VARCHAR(500)    DEFAULT NULL,
  `notes`            TEXT            DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `itx_tenant_type_idx`       (`tenant_id`, `type`),
  KEY `itx_tenant_date_idx`       (`tenant_id`, `transaction_date`),
  KEY `itx_branch_id_fk`          (`branch_id`),
  KEY `itx_warehouse_id_fk`       (`warehouse_id`),
  KEY `itx_warehouse_to_id_fk`    (`warehouse_to_id`),
  KEY `itx_branch_to_id_fk`       (`branch_to_id`),
  KEY `itx_created_by_fk`         (`created_by`),
  CONSTRAINT `itx_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)      REFERENCES `tenants`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `itx_branch_id_foreign`
    FOREIGN KEY (`branch_id`)      REFERENCES `branches`   (`id`) ON DELETE SET NULL,
  CONSTRAINT `itx_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`)   REFERENCES `warehouses` (`id`) ON DELETE SET NULL,
  CONSTRAINT `itx_warehouse_to_id_foreign`
    FOREIGN KEY (`warehouse_to_id`) REFERENCES `warehouses`(`id`) ON DELETE SET NULL,
  CONSTRAINT `itx_branch_to_id_foreign`
    FOREIGN KEY (`branch_to_id`)   REFERENCES `branches`   (`id`) ON DELETE SET NULL,
  CONSTRAINT `itx_created_by_foreign`
    FOREIGN KEY (`created_by`)     REFERENCES `users`      (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Inventory movements: transfers between warehouses/branches, opening stock, spoilage, manual adjustments.';

CREATE TABLE `inventory_transaction_lines` (
  `id`                       CHAR(36)        NOT NULL,
  `tenant_id`                CHAR(36)        NOT NULL,
  `inventory_transaction_id` CHAR(36)        NOT NULL,
  `product_id`               CHAR(36)        NOT NULL,
  `unit_id`                  CHAR(36)        NOT NULL,
  `batch_id`                 CHAR(36)        DEFAULT NULL,
  `serial_id`                CHAR(36)        DEFAULT NULL,
  `quantity`                 DECIMAL(15,4)   NOT NULL,
  `main_unit_quantity`       DECIMAL(15,4)   NOT NULL,
  -- For adjustments: system qty vs actual qty
  `qty_system`               DECIMAL(15,4)   DEFAULT NULL COMMENT 'For adjustment type only',
  `qty_actual`               DECIMAL(15,4)   DEFAULT NULL COMMENT 'For adjustment type only',
  `unit_cost`                DECIMAL(15,4)   DEFAULT NULL,
  `reason`                   VARCHAR(500)    DEFAULT NULL COMMENT 'Per-line reason (spoilage, damage, etc.)',
  `created_at`               TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`               TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`               TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `itxl_tenant_id_idx`                   (`tenant_id`),
  KEY `itxl_inventory_transaction_id_fk`     (`inventory_transaction_id`),
  KEY `itxl_product_id_fk`                   (`product_id`),
  KEY `itxl_unit_id_fk`                      (`unit_id`),
  KEY `itxl_batch_id_fk`                     (`batch_id`),
  KEY `itxl_serial_id_fk`                    (`serial_id`),
  CONSTRAINT `itxl_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)                REFERENCES `tenants`                (`id`) ON DELETE CASCADE,
  CONSTRAINT `itxl_inventory_transaction_id_foreign`
    FOREIGN KEY (`inventory_transaction_id`) REFERENCES `inventory_transactions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `itxl_product_id_foreign`
    FOREIGN KEY (`product_id`)               REFERENCES `products`               (`id`) ON DELETE CASCADE,
  CONSTRAINT `itxl_unit_id_foreign`
    FOREIGN KEY (`unit_id`)                  REFERENCES `units`                  (`id`) ON DELETE CASCADE,
  CONSTRAINT `itxl_batch_id_foreign`
    FOREIGN KEY (`batch_id`)                 REFERENCES `batch_numbers`          (`id`) ON DELETE SET NULL,
  CONSTRAINT `itxl_serial_id_foreign`
    FOREIGN KEY (`serial_id`)                REFERENCES `serial_numbers`         (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Line items for inventory_transactions (transfers, opening stock, spoilage, adjustments).';

-- ─────────────────────────────────────────────────────────
--  Transaction update audit log (covers all three transaction types)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `transaction_update_histories` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `transaction_type` ENUM('sales','purchase','inventory') NOT NULL,
  `transaction_id`   CHAR(36)        NOT NULL COMMENT 'UUID of the row in the relevant transaction table',
  `old_total`        DECIMAL(15,4)   NOT NULL,
  `new_total`        DECIMAL(15,4)   NOT NULL,
  `old_final_price`  DECIMAL(15,4)   NOT NULL,
  `new_final_price`  DECIMAL(15,4)   NOT NULL,
  `changes_summary`  JSON            DEFAULT NULL,
  `updated_by`       CHAR(36)        NOT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tuh_tenant_transaction_idx` (`tenant_id`, `transaction_id`),
  KEY `tuh_updated_by_fk`          (`updated_by`),
  CONSTRAINT `tuh_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tuh_updated_by_foreign`
    FOREIGN KEY (`updated_by`) REFERENCES `users`   (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Audit log for edits across all three transaction tables. transaction_id is a polymorphic UUID.';


-- ============================================================
--  MODULE 09 · PAYMENTS
-- ============================================================

CREATE TABLE `payments` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `contact_id` CHAR(36)        DEFAULT NULL,
  `account_id` CHAR(36)        DEFAULT NULL,
  `amount`     DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `method`     VARCHAR(50)     NOT NULL DEFAULT 'cash' COMMENT 'cash | bank_transfer | check | card',
  `operation`  ENUM('add','subtract') NOT NULL DEFAULT 'add',
  `type`       VARCHAR(100)    DEFAULT NULL COMMENT 'payment classification label',
  `for`        VARCHAR(255)    DEFAULT NULL COMMENT 'free-text description of what this payment covers',
  `created_by` CHAR(36)        DEFAULT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `payments_tenant_id_idx`   (`tenant_id`),
  KEY `payments_contact_id_fk`   (`contact_id`),
  KEY `payments_account_id_fk`   (`account_id`),
  KEY `payments_created_by_fk`   (`created_by`),
  CONSTRAINT `payments_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `payments_contact_id_foreign`
    FOREIGN KEY (`contact_id`) REFERENCES `contacts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `payments_account_id_foreign`
    FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `payments_created_by_foreign`
    FOREIGN KEY (`created_by`) REFERENCES `users`    (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Standalone payment records (prepayments, open payments not tied to a single invoice).';

-- ─────────────────────────────────────────────────────────
--  payment_transactions = individual payment events applied
--  against a specific sales or purchase transaction.
--  Use payments for open/standalone payments; payment_transactions
--  for linking a cash receipt/payment to an invoice.
-- ─────────────────────────────────────────────────────────
CREATE TABLE `payment_transactions` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  -- polymorphic reference to sales_transactions or purchase_transactions
  `transaction_type` ENUM('sales','purchase') NOT NULL,
  `transaction_id`   CHAR(36)        NOT NULL,
  `payment_id`       CHAR(36)        DEFAULT NULL COMMENT 'Link to payments if this settles an open payment',
  `contact_id`       CHAR(36)        DEFAULT NULL,
  `account_id`       CHAR(36)        DEFAULT NULL,
  `amount`           DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `method`           VARCHAR(50)     NOT NULL DEFAULT 'cash',
  `operation`        ENUM('add','subtract') NOT NULL DEFAULT 'add',
  `created_by`       CHAR(36)        DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `pt_tenant_id_idx`      (`tenant_id`),
  KEY `pt_transaction_idx`    (`transaction_type`, `transaction_id`),
  KEY `pt_payment_id_fk`      (`payment_id`),
  KEY `pt_contact_id_fk`      (`contact_id`),
  KEY `pt_account_id_fk`      (`account_id`),
  KEY `pt_created_by_fk`      (`created_by`),
  CONSTRAINT `pt_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `pt_payment_id_foreign`
    FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `pt_contact_id_foreign`
    FOREIGN KEY (`contact_id`) REFERENCES `contacts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `pt_account_id_foreign`
    FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `pt_created_by_foreign`
    FOREIGN KEY (`created_by`) REFERENCES `users`    (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Payment events applied against a specific sales or purchase transaction.';


-- ============================================================
--  MODULE 10 · SALES — QUOTATIONS & ORDERS
-- ============================================================

CREATE TABLE `quotations` (
  `id`                          CHAR(36)        NOT NULL,
  `tenant_id`                   CHAR(36)        NOT NULL,
  `branch_id`                   CHAR(36)        NOT NULL,
  `contact_id`                  CHAR(36)        DEFAULT NULL,
  `ref_no`                      VARCHAR(100)    DEFAULT NULL,
  `quotation_date`              DATE            NOT NULL,
  `expiry_date`                 DATE            DEFAULT NULL,
  `status`                      ENUM('draft','sent','accepted','rejected','converted')
                                NOT NULL DEFAULT 'draft',
  `total`                       DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `discount_type`               ENUM('percentage','fixed') DEFAULT NULL,
  `discount_value`              DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_amount`                  DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `final_price`                 DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `notes`                       TEXT            DEFAULT NULL,
  `converted_to_transaction_id` CHAR(36)        DEFAULT NULL COMMENT 'sales_transactions.id',
  `created_by`                  CHAR(36)        NOT NULL,
  `created_at`                  TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`                  TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`                  TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `q_tenant_id_idx`                    (`tenant_id`),
  KEY `q_branch_id_fk`                     (`branch_id`),
  KEY `q_contact_id_fk`                    (`contact_id`),
  KEY `q_converted_to_transaction_id_fk`   (`converted_to_transaction_id`),
  CONSTRAINT `q_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)                   REFERENCES `tenants`            (`id`) ON DELETE CASCADE,
  CONSTRAINT `q_branch_id_foreign`
    FOREIGN KEY (`branch_id`)                   REFERENCES `branches`           (`id`) ON DELETE RESTRICT,
  CONSTRAINT `q_contact_id_foreign`
    FOREIGN KEY (`contact_id`)                  REFERENCES `contacts`           (`id`) ON DELETE SET NULL,
  CONSTRAINT `q_converted_to_transaction_id_foreign`
    FOREIGN KEY (`converted_to_transaction_id`) REFERENCES `sales_transactions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `q_created_by_foreign`
    FOREIGN KEY (`created_by`)                  REFERENCES `users`              (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `quotation_lines` (
  `id`           CHAR(36)        NOT NULL,
  `quotation_id` CHAR(36)        NOT NULL,
  `product_id`   CHAR(36)        NOT NULL,
  `unit_id`      CHAR(36)        NOT NULL,
  `quantity`     DECIMAL(15,4)   NOT NULL,
  `unit_price`   DECIMAL(15,4)   NOT NULL,
  `discount`     DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_rate`     DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
  `total`        DECIMAL(15,4)   NOT NULL,
  `deleted_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ql_quotation_id_fk` (`quotation_id`),
  KEY `ql_product_id_fk`   (`product_id`),
  CONSTRAINT `ql_quotation_id_foreign`
    FOREIGN KEY (`quotation_id`) REFERENCES `quotations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ql_product_id_foreign`
    FOREIGN KEY (`product_id`)   REFERENCES `products`   (`id`) ON DELETE CASCADE,
  CONSTRAINT `ql_unit_id_foreign`
    FOREIGN KEY (`unit_id`)      REFERENCES `units`      (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
--  Orders (B2B portal orders — pre-invoice)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `orders` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `branch_id`        CHAR(36)        NOT NULL,
  `warehouse_id`     CHAR(36)        DEFAULT NULL,
  `contact_id`       CHAR(36)        DEFAULT NULL,
  `ref_no`           VARCHAR(100)    DEFAULT NULL,
  `order_date`       DATE            NOT NULL,
  `expected_date`    DATE            DEFAULT NULL,
  `subtotal`         DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `discount_value`   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_amount`       DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `total`            DECIMAL(15,4)   NOT NULL,
  `status`           ENUM('pending','confirmed','cancelled','converted') NOT NULL DEFAULT 'pending',
  `converted_to_transaction_id` CHAR(36) DEFAULT NULL COMMENT 'sales_transactions.id',
  `notes`            TEXT            DEFAULT NULL,
  `created_by`       CHAR(36)        NOT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `orders_tenant_id_idx`   (`tenant_id`),
  KEY `orders_branch_id_fk`    (`branch_id`),
  KEY `orders_warehouse_id_fk` (`warehouse_id`),
  KEY `orders_contact_id_fk`   (`contact_id`),
  KEY `orders_created_by_fk`   (`created_by`),
  CONSTRAINT `orders_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants`            (`id`) ON DELETE CASCADE,
  CONSTRAINT `orders_branch_id_foreign`
    FOREIGN KEY (`branch_id`)    REFERENCES `branches`           (`id`) ON DELETE RESTRICT,
  CONSTRAINT `orders_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses`         (`id`) ON DELETE SET NULL,
  CONSTRAINT `orders_contact_id_foreign`
    FOREIGN KEY (`contact_id`)   REFERENCES `contacts`           (`id`) ON DELETE SET NULL,
  CONSTRAINT `orders_converted_to_foreign`
    FOREIGN KEY (`converted_to_transaction_id`) REFERENCES `sales_transactions`(`id`) ON DELETE SET NULL,
  CONSTRAINT `orders_created_by_foreign`
    FOREIGN KEY (`created_by`)   REFERENCES `users`              (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='B2B/portal orders. Pre-invoice stage.';

CREATE TABLE `order_items` (
  `id`         CHAR(36)        NOT NULL,
  `order_id`   CHAR(36)        NOT NULL,
  `product_id` CHAR(36)        NOT NULL,
  `unit_id`    CHAR(36)        NOT NULL,
  `quantity`   DECIMAL(15,4)   NOT NULL,
  `price`      DECIMAL(15,4)   NOT NULL,
  `discount`   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `subtotal`   DECIMAL(15,4)   NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `oi_order_id_fk`   (`order_id`),
  KEY `oi_product_id_fk` (`product_id`),
  CONSTRAINT `oi_order_id_foreign`
    FOREIGN KEY (`order_id`)   REFERENCES `orders`   (`id`) ON DELETE CASCADE,
  CONSTRAINT `oi_product_id_foreign`
    FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `oi_unit_id_foreign`
    FOREIGN KEY (`unit_id`)    REFERENCES `units`    (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
--  MODULE 11 · PURCHASING — PURCHASE ORDERS
-- ============================================================

CREATE TABLE `purchase_orders` (
  `id`            CHAR(36)        NOT NULL,
  `tenant_id`     CHAR(36)        NOT NULL,
  `branch_id`     CHAR(36)        NOT NULL,
  `warehouse_id`  CHAR(36)        DEFAULT NULL,
  `contact_id`    CHAR(36)        NOT NULL COMMENT 'Supplier',
  `ref_no`        VARCHAR(100)    DEFAULT NULL,
  `po_date`       DATE            NOT NULL,
  `expected_date` DATE            DEFAULT NULL,
  `status`        ENUM('draft','sent','partial','received','cancelled') NOT NULL DEFAULT 'draft',
  `total`         DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_amount`    DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `shipping_cost` DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `final_price`   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `notes`         TEXT            DEFAULT NULL,
  `created_by`    CHAR(36)        NOT NULL,
  `created_at`    TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `po_tenant_id_idx`    (`tenant_id`),
  KEY `po_branch_id_fk`     (`branch_id`),
  KEY `po_warehouse_id_fk`  (`warehouse_id`),
  KEY `po_contact_id_fk`    (`contact_id`),
  KEY `po_created_by_fk`    (`created_by`),
  CONSTRAINT `po_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `po_branch_id_foreign`
    FOREIGN KEY (`branch_id`)    REFERENCES `branches`   (`id`) ON DELETE RESTRICT,
  CONSTRAINT `po_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE SET NULL,
  CONSTRAINT `po_contact_id_foreign`
    FOREIGN KEY (`contact_id`)   REFERENCES `contacts`   (`id`) ON DELETE RESTRICT,
  CONSTRAINT `po_created_by_foreign`
    FOREIGN KEY (`created_by`)   REFERENCES `users`      (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `purchase_order_lines` (
  `id`                CHAR(36)        NOT NULL,
  `purchase_order_id` CHAR(36)        NOT NULL,
  `product_id`        CHAR(36)        NOT NULL,
  `unit_id`           CHAR(36)        NOT NULL,
  `quantity_ordered`  DECIMAL(15,4)   NOT NULL,
  `quantity_received` DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `unit_price`        DECIMAL(15,4)   NOT NULL,
  `discount`          DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_rate`          DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
  `total`             DECIMAL(15,4)   NOT NULL,
  `deleted_at`        TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `pol_purchase_order_id_fk` (`purchase_order_id`),
  KEY `pol_product_id_fk`        (`product_id`),
  CONSTRAINT `pol_purchase_order_id_foreign`
    FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pol_product_id_foreign`
    FOREIGN KEY (`product_id`)        REFERENCES `products`        (`id`) ON DELETE CASCADE,
  CONSTRAINT `pol_unit_id_foreign`
    FOREIGN KEY (`unit_id`)           REFERENCES `units`           (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add deferred FK: purchase_transactions → purchase_orders
ALTER TABLE `purchase_transactions`
  ADD CONSTRAINT `ptx_purchase_order_id_foreign`
    FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE SET NULL;


-- ============================================================
--  MODULE 12 · CRM
-- ============================================================

CREATE TABLE `crm_leads` (
  `id`                  CHAR(36)        NOT NULL,
  `tenant_id`           CHAR(36)        NOT NULL,
  `contact_id`          CHAR(36)        DEFAULT NULL COMMENT 'Set when lead converts to contact',
  `name_en`             VARCHAR(255)    NOT NULL,
  `name_ar`             VARCHAR(255)    NOT NULL,
  `email`               VARCHAR(255)    DEFAULT NULL,
  `phone`               VARCHAR(50)     DEFAULT NULL,
  `company`             VARCHAR(255)    DEFAULT NULL,
  `source`              ENUM('website','referral','social','cold_call','exhibition','other') DEFAULT NULL,
  `status`              ENUM('new','contacted','qualified','proposal','negotiation','won','lost')
                        NOT NULL DEFAULT 'new',
  `assigned_to`         CHAR(36)        DEFAULT NULL,
  `estimated_value`     DECIMAL(15,4)   DEFAULT NULL,
  `expected_close_date` DATE            DEFAULT NULL,
  `notes`               TEXT            DEFAULT NULL,
  `created_by`          CHAR(36)        NOT NULL,
  `created_at`          TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`          TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `leads_tenant_status_idx`   (`tenant_id`, `status`),
  KEY `leads_tenant_assigned_idx` (`tenant_id`, `assigned_to`),
  KEY `leads_contact_id_fk`       (`contact_id`),
  KEY `leads_assigned_to_fk`      (`assigned_to`),
  CONSTRAINT `leads_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)   REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `leads_contact_id_foreign`
    FOREIGN KEY (`contact_id`)  REFERENCES `contacts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `leads_assigned_to_foreign`
    FOREIGN KEY (`assigned_to`) REFERENCES `users`    (`id`) ON DELETE SET NULL,
  CONSTRAINT `leads_created_by_foreign`
    FOREIGN KEY (`created_by`)  REFERENCES `users`    (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `crm_activities` (
  `id`           CHAR(36)        NOT NULL,
  `tenant_id`    CHAR(36)        NOT NULL,
  `lead_id`      CHAR(36)        DEFAULT NULL,
  `contact_id`   CHAR(36)        DEFAULT NULL,
  `type`         ENUM('call','meeting','email','note','task') NOT NULL,
  `subject`      VARCHAR(255)    DEFAULT NULL,
  `description`  TEXT            DEFAULT NULL,
  `due_date`     TIMESTAMP       NULL DEFAULT NULL,
  `completed_at` TIMESTAMP       NULL DEFAULT NULL,
  `outcome`      VARCHAR(500)    DEFAULT NULL,
  `assigned_to`  CHAR(36)        DEFAULT NULL,
  `created_by`   CHAR(36)        NOT NULL,
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`   TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `crma_tenant_id_idx`    (`tenant_id`),
  KEY `crma_lead_id_fk`       (`lead_id`),
  KEY `crma_contact_id_fk`    (`contact_id`),
  KEY `crma_assigned_to_fk`   (`assigned_to`),
  CONSTRAINT `crma_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)   REFERENCES `tenants`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `crma_lead_id_foreign`
    FOREIGN KEY (`lead_id`)     REFERENCES `crm_leads`  (`id`) ON DELETE SET NULL,
  CONSTRAINT `crma_contact_id_foreign`
    FOREIGN KEY (`contact_id`)  REFERENCES `contacts`   (`id`) ON DELETE SET NULL,
  CONSTRAINT `crma_assigned_to_foreign`
    FOREIGN KEY (`assigned_to`) REFERENCES `users`      (`id`) ON DELETE SET NULL,
  CONSTRAINT `crma_created_by_foreign`
    FOREIGN KEY (`created_by`)  REFERENCES `users`      (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
--  MODULE 13 · HR & PAYROLL
-- ============================================================

CREATE TABLE `departments` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `branch_id`  CHAR(36)        DEFAULT NULL,
  `parent_id`  CHAR(36)        DEFAULT NULL,
  `name_en`    VARCHAR(255)    NOT NULL,
  `name_ar`    VARCHAR(255)    NOT NULL,
  `code`       VARCHAR(50)     DEFAULT NULL,
  `manager_id` CHAR(36)        DEFAULT NULL COMMENT 'FK to employees — added via ALTER after employees',
  `is_active`  TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `dept_tenant_id_idx` (`tenant_id`),
  KEY `dept_branch_id_fk`  (`branch_id`),
  KEY `dept_parent_id_fk`  (`parent_id`),
  CONSTRAINT `dept_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants`     (`id`) ON DELETE CASCADE,
  CONSTRAINT `dept_branch_id_foreign`
    FOREIGN KEY (`branch_id`) REFERENCES `branches`    (`id`) ON DELETE SET NULL,
  CONSTRAINT `dept_parent_id_foreign`
    FOREIGN KEY (`parent_id`) REFERENCES `departments` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `job_positions` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `department_id`    CHAR(36)        DEFAULT NULL,
  `title_en`         VARCHAR(255)    NOT NULL,
  `title_ar`         VARCHAR(255)    NOT NULL,
  `description_en`   TEXT            DEFAULT NULL,
  `description_ar`   TEXT            DEFAULT NULL,
  `min_salary`    DECIMAL(15,4)   DEFAULT NULL,
  `max_salary`    DECIMAL(15,4)   DEFAULT NULL,
  `is_active`     TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `jp_tenant_id_idx`      (`tenant_id`),
  KEY `jp_department_id_fk`   (`department_id`),
  CONSTRAINT `jp_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)     REFERENCES `tenants`     (`id`) ON DELETE CASCADE,
  CONSTRAINT `jp_department_id_foreign`
    FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `employees` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `user_id`          CHAR(36)        DEFAULT NULL COMMENT 'If employee has system login',
  `branch_id`        CHAR(36)        DEFAULT NULL,
  `department_id`    CHAR(36)        DEFAULT NULL,
  `job_position_id`  CHAR(36)        DEFAULT NULL,
  `employee_code`    VARCHAR(50)     DEFAULT NULL,
  `first_name`       VARCHAR(100)    NOT NULL,
  `last_name`        VARCHAR(100)    NOT NULL,
  `national_id`      VARCHAR(50)     DEFAULT NULL,
  `gender`           ENUM('male','female') DEFAULT NULL,
  `birth_date`       DATE            DEFAULT NULL,
  `hire_date`        DATE            NOT NULL,
  `termination_date` DATE            DEFAULT NULL,
  `employment_type`  ENUM('full_time','part_time','contractor','intern') NOT NULL DEFAULT 'full_time',
  `status`           ENUM('active','inactive','on_leave','terminated')   NOT NULL DEFAULT 'active',
  `email`            VARCHAR(255)    DEFAULT NULL,
  `phone`            VARCHAR(50)     DEFAULT NULL,
  `address`          TEXT            DEFAULT NULL,
  `governorate_id`   CHAR(36)        DEFAULT NULL,
  `city_id`          CHAR(36)        DEFAULT NULL,
  `bank_account_no`  VARCHAR(100)    DEFAULT NULL,
  `bank_name`        VARCHAR(255)    DEFAULT NULL,
  `base_salary`      DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `salary_type`      ENUM('monthly','daily','hourly') NOT NULL DEFAULT 'monthly',
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `emp_tenant_id_idx`       (`tenant_id`),
  KEY `emp_tenant_code_idx`     (`tenant_id`, `employee_code`),
  KEY `emp_user_id_fk`          (`user_id`),
  KEY `emp_branch_id_fk`        (`branch_id`),
  KEY `emp_department_id_fk`    (`department_id`),
  KEY `emp_job_position_id_fk`  (`job_position_id`),
  CONSTRAINT `emp_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)       REFERENCES `tenants`       (`id`) ON DELETE CASCADE,
  CONSTRAINT `emp_user_id_foreign`
    FOREIGN KEY (`user_id`)         REFERENCES `users`         (`id`) ON DELETE SET NULL,
  CONSTRAINT `emp_branch_id_foreign`
    FOREIGN KEY (`branch_id`)       REFERENCES `branches`      (`id`) ON DELETE SET NULL,
  CONSTRAINT `emp_department_id_foreign`
    FOREIGN KEY (`department_id`)   REFERENCES `departments`   (`id`) ON DELETE SET NULL,
  CONSTRAINT `emp_job_position_id_foreign`
    FOREIGN KEY (`job_position_id`) REFERENCES `job_positions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `emp_governorate_id_foreign`
    FOREIGN KEY (`governorate_id`)  REFERENCES `governorates`  (`id`) ON DELETE SET NULL,
  CONSTRAINT `emp_city_id_foreign`
    FOREIGN KEY (`city_id`)         REFERENCES `cities`        (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add deferred FK: departments.manager_id → employees
ALTER TABLE `departments`
  ADD KEY `dept_manager_id_fk` (`manager_id`),
  ADD CONSTRAINT `dept_manager_id_foreign`
    FOREIGN KEY (`manager_id`) REFERENCES `employees` (`id`) ON DELETE SET NULL;

-- ─────────────────────────────────────────────────────────
CREATE TABLE `attendance_logs` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `employee_id`    CHAR(36)        NOT NULL,
  `date`           DATE            NOT NULL,
  `check_in`       TIMESTAMP       NULL DEFAULT NULL,
  `check_out`      TIMESTAMP       NULL DEFAULT NULL,
  `status`         ENUM('present','absent','late','half_day','leave') NOT NULL DEFAULT 'present',
  `overtime_hours` DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
  `note`           TEXT            DEFAULT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `attendance_employee_date_unique` (`tenant_id`, `employee_id`, `date`),
  KEY `att_tenant_date_idx`   (`tenant_id`, `date`),
  KEY `att_employee_id_fk`    (`employee_id`),
  CONSTRAINT `att_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)   REFERENCES `tenants`   (`id`) ON DELETE CASCADE,
  CONSTRAINT `att_employee_id_foreign`
    FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `leave_types` (
  `id`           CHAR(36)        NOT NULL,
  `tenant_id`    CHAR(36)        NOT NULL,
  `name_en`      VARCHAR(100)    NOT NULL COMMENT 'Annual | Sick | Emergency',
  `name_ar`      VARCHAR(100)    NOT NULL,
  `days_allowed` INT             NOT NULL DEFAULT 0,
  `is_paid`      TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`   TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `lt_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `lt_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `leave_requests` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `employee_id`    CHAR(36)        NOT NULL,
  `leave_type_id`  CHAR(36)        NOT NULL,
  `start_date`     DATE            NOT NULL,
  `end_date`       DATE            NOT NULL,
  `days_count`     INT             NOT NULL,
  `reason`         TEXT            DEFAULT NULL,
  `status`         ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `approved_by`    CHAR(36)        DEFAULT NULL,
  `approved_at`    TIMESTAMP       NULL DEFAULT NULL,
  `rejection_note` TEXT            DEFAULT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `lr_tenant_employee_idx` (`tenant_id`, `employee_id`),
  KEY `lr_employee_id_fk`      (`employee_id`),
  KEY `lr_leave_type_id_fk`    (`leave_type_id`),
  KEY `lr_approved_by_fk`      (`approved_by`),
  CONSTRAINT `lr_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)     REFERENCES `tenants`     (`id`) ON DELETE CASCADE,
  CONSTRAINT `lr_employee_id_foreign`
    FOREIGN KEY (`employee_id`)   REFERENCES `employees`   (`id`) ON DELETE CASCADE,
  CONSTRAINT `lr_leave_type_id_foreign`
    FOREIGN KEY (`leave_type_id`) REFERENCES `leave_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `lr_approved_by_foreign`
    FOREIGN KEY (`approved_by`)   REFERENCES `users`       (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `salary_components` (
  `id`          CHAR(36)        NOT NULL,
  `tenant_id`   CHAR(36)        NOT NULL,
  `name_en`     VARCHAR(255)    NOT NULL COMMENT 'Housing Allowance | Social Insurance',
  `name_ar`     VARCHAR(255)    NOT NULL,
  `type`        ENUM('allowance','deduction') NOT NULL,
  `calculation` ENUM('fixed','percentage') NOT NULL DEFAULT 'fixed',
  `value`       DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `is_taxable`  TINYINT(1)      NOT NULL DEFAULT 0,
  `is_active`   TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at`  TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`  TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`  TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sc_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `sc_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `employee_salary_components` (
  `id`                  CHAR(36)        NOT NULL,
  `employee_id`         CHAR(36)        NOT NULL,
  `salary_component_id` CHAR(36)        NOT NULL,
  `value`               DECIMAL(15,4)   NOT NULL,
  `effective_from`      DATE            DEFAULT NULL,
  `effective_to`        DATE            DEFAULT NULL,
  `deleted_at`          TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `esc_employee_id_fk`         (`employee_id`),
  KEY `esc_salary_component_id_fk` (`salary_component_id`),
  CONSTRAINT `esc_employee_id_foreign`
    FOREIGN KEY (`employee_id`)         REFERENCES `employees`         (`id`) ON DELETE CASCADE,
  CONSTRAINT `esc_salary_component_id_foreign`
    FOREIGN KEY (`salary_component_id`) REFERENCES `salary_components` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `payroll_periods` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `name`             VARCHAR(100)    DEFAULT NULL,
  `period_start`     DATE            NOT NULL,
  `period_end`       DATE            NOT NULL,
  `payment_date`     DATE            DEFAULT NULL,
  `status`           ENUM('draft','approved','paid') NOT NULL DEFAULT 'draft',
  `total_gross`      DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `total_net`        DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `total_deductions` DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `processed_by`     CHAR(36)        DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `pp_tenant_id_idx`     (`tenant_id`),
  KEY `pp_processed_by_fk`   (`processed_by`),
  CONSTRAINT `pp_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pp_processed_by_foreign`
    FOREIGN KEY (`processed_by`) REFERENCES `users`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `payroll_slips` (
  `id`                CHAR(36)        NOT NULL,
  `tenant_id`         CHAR(36)        NOT NULL,
  `payroll_period_id` CHAR(36)        NOT NULL,
  `employee_id`       CHAR(36)        NOT NULL,
  `base_salary`       DECIMAL(15,4)   NOT NULL,
  `total_allowances`  DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `total_deductions`  DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `overtime_pay`      DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `gross_salary`      DECIMAL(15,4)   NOT NULL,
  `tax_amount`        DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `net_salary`        DECIMAL(15,4)   NOT NULL,
  `working_days`      SMALLINT        NOT NULL DEFAULT 0,
  `absent_days`       SMALLINT        NOT NULL DEFAULT 0,
  `leave_days`        SMALLINT        NOT NULL DEFAULT 0,
  `payment_method`    ENUM('bank_transfer','cash','check') NOT NULL DEFAULT 'bank_transfer',
  `paid_at`           TIMESTAMP       NULL DEFAULT NULL,
  `lines`             JSON            DEFAULT NULL COMMENT 'Breakdown of salary components',
  `created_at`        TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`        TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`        TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `payroll_slips_period_employee_unique` (`tenant_id`, `payroll_period_id`, `employee_id`),
  KEY `ps_tenant_id_idx`         (`tenant_id`),
  KEY `ps_payroll_period_id_fk`  (`payroll_period_id`),
  KEY `ps_employee_id_fk`        (`employee_id`),
  CONSTRAINT `ps_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)         REFERENCES `tenants`         (`id`) ON DELETE CASCADE,
  CONSTRAINT `ps_payroll_period_id_foreign`
    FOREIGN KEY (`payroll_period_id`) REFERENCES `payroll_periods` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ps_employee_id_foreign`
    FOREIGN KEY (`employee_id`)       REFERENCES `employees`       (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
--  MODULE 14 · REPORTING & ANALYTICS
-- ============================================================

CREATE TABLE `report_templates` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `name_en`    VARCHAR(255)    NOT NULL,
  `name_ar`    VARCHAR(255)    NOT NULL,
  `module`     VARCHAR(100)    DEFAULT NULL COMMENT 'sales | inventory | finance | hr',
  `filters`    JSON            DEFAULT NULL,
  `columns`    JSON            DEFAULT NULL,
  `is_shared`  TINYINT(1)      NOT NULL DEFAULT 0,
  `created_by` CHAR(36)        NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `rt_tenant_id_idx`  (`tenant_id`),
  KEY `rt_created_by_fk`  (`created_by`),
  CONSTRAINT `rt_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `rt_created_by_foreign`
    FOREIGN KEY (`created_by`) REFERENCES `users`  (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `scheduled_reports` (
  `id`                 CHAR(36)        NOT NULL,
  `tenant_id`          CHAR(36)        NOT NULL,
  `report_template_id` CHAR(36)        DEFAULT NULL,
  `name_en`            VARCHAR(255)    NOT NULL,
  `name_ar`            VARCHAR(255)    NOT NULL,
  `frequency`          ENUM('daily','weekly','monthly') NOT NULL,
  `send_at`            TIME            DEFAULT NULL,
  `recipients`         JSON            DEFAULT NULL,
  `format`             ENUM('pdf','excel','csv') NOT NULL DEFAULT 'pdf',
  `is_active`          TINYINT(1)      NOT NULL DEFAULT 1,
  `last_sent_at`       TIMESTAMP       NULL DEFAULT NULL,
  `created_by`         CHAR(36)        NOT NULL,
  `created_at`         TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`         TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`         TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sr_tenant_id_idx`          (`tenant_id`),
  KEY `sr_report_template_id_fk`  (`report_template_id`),
  CONSTRAINT `sr_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)          REFERENCES `tenants`          (`id`) ON DELETE CASCADE,
  CONSTRAINT `sr_report_template_id_foreign`
    FOREIGN KEY (`report_template_id`) REFERENCES `report_templates` (`id`) ON DELETE SET NULL,
  CONSTRAINT `sr_created_by_foreign`
    FOREIGN KEY (`created_by`)         REFERENCES `users`            (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kpi_snapshots` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `date`       DATE            NOT NULL,
  `metric`     VARCHAR(100)    NOT NULL COMMENT 'total_sales | gross_profit | new_customers',
  `value`      DECIMAL(20,4)   NOT NULL,
  `branch_id`  CHAR(36)        DEFAULT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `kpi_tenant_date_metric_branch_unique` (`tenant_id`, `date`, `metric`, `branch_id`),
  KEY `kpi_tenant_metric_idx` (`tenant_id`, `metric`, `date`),
  KEY `kpi_branch_id_fk`      (`branch_id`),
  CONSTRAINT `kpi_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `kpi_branch_id_foreign`
    FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Nightly pre-computed KPI values for dashboard performance.';


-- ============================================================
--  MODULE 15 · SYSTEM
-- ============================================================

CREATE TABLE `activity_log` (
  `id`           CHAR(36)        NOT NULL,
  `tenant_id`    CHAR(36)        NOT NULL,
  `user_id`      CHAR(36)        NOT NULL,
  `subject_id`   CHAR(36)        DEFAULT NULL,
  `subject_type` VARCHAR(255)    DEFAULT NULL,
  `event`        VARCHAR(100)    DEFAULT NULL COMMENT 'created | updated | deleted',
  `module`       VARCHAR(100)    DEFAULT NULL COMMENT 'sales | inventory | hr | finance',
  `description`  VARCHAR(500)    DEFAULT NULL,
  `title`        VARCHAR(255)    NOT NULL,
  `properties`   JSON            DEFAULT NULL COMMENT 'Before/after diff',
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`   TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `al_tenant_id_idx`     (`tenant_id`),
  KEY `al_tenant_module_idx` (`tenant_id`, `module`),
  KEY `al_user_id_fk`        (`user_id`),
  CONSTRAINT `al_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `al_user_id_foreign`
    FOREIGN KEY (`user_id`)   REFERENCES `users`   (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Custom ActivityLog module — audit trail for all model changes.';

CREATE TABLE `notifications` (
  `id`              CHAR(36)        NOT NULL,
  `type`            VARCHAR(255)    NOT NULL,
  `notifiable_type` VARCHAR(255)    NOT NULL,
  `notifiable_id`   CHAR(36)        NOT NULL,
  `data`            JSON            NOT NULL,
  `read_at`         TIMESTAMP       NULL DEFAULT NULL,
  `created_at`      TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`      TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`      TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `notifications_notifiable_idx` (`notifiable_type`, `notifiable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `failed_jobs` (
  `id`         CHAR(36)        NOT NULL,
  `uuid`       VARCHAR(255)    NOT NULL,
  `connection` TEXT            NOT NULL,
  `queue`      TEXT            NOT NULL,
  `payload`    LONGTEXT        NOT NULL,
  `exception`  LONGTEXT        NOT NULL,
  `failed_at`  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `migrations` (
  `id`        CHAR(36)        NOT NULL,
  `migration` VARCHAR(255)    NOT NULL,
  `batch`     INT             NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
--  END OF SCHEMA  — RAKEEZA ERP v4.0
-- ============================================================
