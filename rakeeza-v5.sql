-- ============================================================
--  RAKEEZA ERP — Normalized & Modular Database Schema
--  MySQL 8.0+ · Single DB Multi-Tenancy · Laravel 13
--  Version: 5.0 | May 2026
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
  `profile_image`      VARCHAR(500)    DEFAULT NULL,
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
--  CENTRAL · TENANCY & SUBSCRIPTION
-- ============================================================

CREATE TABLE `plans` (
  `plan_id`         CHAR(36)        NOT NULL,
  `name_en`         VARCHAR(150)    NOT NULL,
  `name_ar`         VARCHAR(150)    NOT NULL,
  `price`           DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `billing_cycle`   TINYINT         NOT NULL DEFAULT 1 COMMENT '1=monthly | 2=quarterly | 3=yearly',
  `trial_days`      SMALLINT        NOT NULL DEFAULT 0,
  `max_users`       INT             DEFAULT NULL COMMENT 'NULL = unlimited',
  `max_branches`    INT             DEFAULT NULL COMMENT 'NULL = unlimited',
  `is_active`       TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`      TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`      TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`plan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='SaaS subscription tiers.';

CREATE TABLE `plan_limits` (
  `plan_limit_id`  CHAR(36)        NOT NULL,
  `plan_id`        CHAR(36)        NOT NULL,
  `key`            VARCHAR(100)    NOT NULL COMMENT 'e.g. max_products | max_warehouses',
  `value`          INT             NOT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`plan_limit_id`),
  UNIQUE KEY `uq_plan_limit_key` (`plan_id`, `key`),
  CONSTRAINT `fk_plan_limits_plan`
    FOREIGN KEY (`plan_id`) REFERENCES `plans` (`plan_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `features` (
  `feature_id`  CHAR(36)        NOT NULL,
  `name_en`     VARCHAR(150)    NOT NULL,
  `name_ar`     VARCHAR(150)    NOT NULL,
  `code`        VARCHAR(100)    NOT NULL,
  `description_en` TEXT         DEFAULT NULL,
  `description_ar` TEXT         DEFAULT NULL,
  `is_active`   TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at`  TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`  TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`feature_id`),
  UNIQUE KEY `features_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Feature flags available in the platform.';

CREATE TABLE `plan_features` (
  `plan_feature_id` CHAR(36)    NOT NULL,
  `plan_id`         CHAR(36)    NOT NULL,
  `feature_id`      CHAR(36)    NOT NULL,
  `enabled`         TINYINT(1)  NOT NULL DEFAULT 1,
  PRIMARY KEY (`plan_feature_id`),
  UNIQUE KEY `uq_plan_feature` (`plan_id`, `feature_id`),
  CONSTRAINT `fk_plan_features_plan`
    FOREIGN KEY (`plan_id`)    REFERENCES `plans`    (`plan_id`)    ON DELETE CASCADE,
  CONSTRAINT `fk_plan_features_feature`
    FOREIGN KEY (`feature_id`) REFERENCES `features` (`feature_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
--  TENANTS
-- ─────────────────────────────────────────────────────────
CREATE TABLE `tenants` (
  `id`            CHAR(36)        NOT NULL,
  `name_en`       VARCHAR(255)    NOT NULL,
  `name_ar`       VARCHAR(255)    NOT NULL,
  `slug`          VARCHAR(100)    NOT NULL COMMENT 'subdomain: slug.rakeeza.com',
  `email`         VARCHAR(255)    NOT NULL COMMENT 'Owner / billing email',
  `phone`         VARCHAR(50)     DEFAULT NULL,
  `logo`          VARCHAR(500)    DEFAULT NULL,
  `status`        TINYINT         NOT NULL DEFAULT 1 COMMENT '1=active | 2=suspended | 3=cancelled',
  `trial_ends_at` TIMESTAMP       NULL DEFAULT NULL,
  `plan_id`       CHAR(36)        DEFAULT NULL,
  `created_at`    TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tenants_slug_unique`  (`slug`),
  UNIQUE KEY `tenants_email_unique` (`email`),
  KEY `tenants_plan_id_fk`          (`plan_id`),
  KEY `tenants_status_idx`          (`status`),
  CONSTRAINT `tenants_plan_id_foreign`
    FOREIGN KEY (`plan_id`) REFERENCES `plans` (`plan_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One row per business/company using the SaaS platform.';

-- ─────────────────────────────────────────────────────────
--  CENTRAL · DOMAINS  (custom domain mapping per tenant)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `domains` (
  `id`          CHAR(36)        NOT NULL,
  `tenant_id`   CHAR(36)        NOT NULL,
  `domain`      VARCHAR(255)    NOT NULL COMMENT 'e.g. erp.mycorp.com',
  `status`      TINYINT         NOT NULL DEFAULT 1 COMMENT '1=active | 2=inactive | 3=pending_verification',
  `verified_at` TIMESTAMP       NULL DEFAULT NULL,
  `created_at`  TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`  TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `domains_domain_unique` (`domain`),
  KEY `domains_tenant_id_fk` (`tenant_id`),
  CONSTRAINT `domains_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Custom domain mappings per tenant.';

-- ─────────────────────────────────────────────────────────
--  CENTRAL · SUBSCRIPTIONS & BILLING
-- ─────────────────────────────────────────────────────────
CREATE TABLE `subscriptions` (
  `subscription_id`     CHAR(36)        NOT NULL,
  `tenant_id`           CHAR(36)        NOT NULL,
  `plan_id`             CHAR(36)        NOT NULL,
  `price_at_purchase`   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `currency_at_purchase` CHAR(3)        NOT NULL DEFAULT 'EGP',
  `status`              TINYINT         NOT NULL DEFAULT 1 COMMENT '1=active | 2=cancelled | 3=expired | 4=past_due',
  `start_date`          TIMESTAMP       NOT NULL,
  `ends_at`             TIMESTAMP       NOT NULL,
  `auto_renew`          TINYINT(1)      NOT NULL DEFAULT 1,
  `canceled_at`         TIMESTAMP       NULL DEFAULT NULL,
  `cancel_reason`       VARCHAR(500)    DEFAULT NULL,
  `created_at`          TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`subscription_id`),
  KEY `subscriptions_tenant_status_idx` (`tenant_id`, `status`),
  KEY `subscriptions_plan_id_fk`        (`plan_id`),
  CONSTRAINT `subscriptions_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `subscriptions_plan_id_foreign`
    FOREIGN KEY (`plan_id`)   REFERENCES `plans`   (`plan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `subscription_history` (
  `history_id`       CHAR(36)        NOT NULL,
  `subscription_id`  CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `old_plan_id`      CHAR(36)        DEFAULT NULL,
  `new_plan_id`      CHAR(36)        DEFAULT NULL,
  `change_type`      TINYINT         NOT NULL COMMENT '1=upgrade | 2=downgrade | 3=renew | 4=cancel',
  `changed_by`       CHAR(36)        DEFAULT NULL COMMENT 'platform_users.id',
  `notes`            TEXT            DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`history_id`),
  KEY `sub_hist_tenant_idx`       (`tenant_id`),
  KEY `sub_hist_subscription_fk`  (`subscription_id`),
  KEY `sub_hist_old_plan_fk`      (`old_plan_id`),
  KEY `sub_hist_new_plan_fk`      (`new_plan_id`),
  CONSTRAINT `sub_hist_subscription_foreign`
    FOREIGN KEY (`subscription_id`) REFERENCES `subscriptions` (`subscription_id`),
  CONSTRAINT `sub_hist_old_plan_foreign`
    FOREIGN KEY (`old_plan_id`)     REFERENCES `plans`         (`plan_id`) ON DELETE SET NULL,
  CONSTRAINT `sub_hist_new_plan_foreign`
    FOREIGN KEY (`new_plan_id`)     REFERENCES `plans`         (`plan_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `invoices` (
  `invoice_id`          CHAR(36)        NOT NULL,
  `tenant_id`           CHAR(36)        NOT NULL,
  `subscription_id`     CHAR(36)        DEFAULT NULL,
  `invoice_number`      VARCHAR(50)     NOT NULL,
  `subtotal`            DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_amount`          DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `discount_amount`     DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `total_amount`        DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `paid_amount`         DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `currency`            CHAR(3)         NOT NULL DEFAULT 'EGP',
  `status`              TINYINT         NOT NULL DEFAULT 1 COMMENT '1=draft | 2=unpaid | 3=paid | 4=overdue | 5=cancelled',
  `due_date`            DATE            DEFAULT NULL,
  `issued_at`           TIMESTAMP       NULL DEFAULT NULL,
  `paid_at`             TIMESTAMP       NULL DEFAULT NULL,
  `cancelled_at`        TIMESTAMP       NULL DEFAULT NULL,
  `cancellation_reason` VARCHAR(500)    DEFAULT NULL,
  `metadata`            JSON            DEFAULT NULL,
  `created_at`          TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`invoice_id`),
  UNIQUE KEY `invoices_number_unique`          (`invoice_number`),
  KEY `invoices_tenant_status_idx`             (`tenant_id`, `status`),
  KEY `invoices_tenant_due_idx`                (`tenant_id`, `due_date`),
  KEY `invoices_subscription_id_fk`            (`subscription_id`),
  CONSTRAINT `invoices_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)      REFERENCES `tenants`       (`id`) ON DELETE CASCADE,
  CONSTRAINT `invoices_subscription_id_foreign`
    FOREIGN KEY (`subscription_id`) REFERENCES `subscriptions` (`subscription_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `payment_methods` (
  `payment_method_id` TINYINT         NOT NULL,
  `code`              VARCHAR(50)     NOT NULL,
  `name_en`           VARCHAR(100)    NOT NULL,
  `name_ar`           VARCHAR(100)    NOT NULL,
  `is_active`         TINYINT(1)      NOT NULL DEFAULT 1,
  PRIMARY KEY (`payment_method_id`),
  UNIQUE KEY `payment_methods_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Lookup table for payment methods. Seeded, not editable.';

CREATE TABLE `payments` (
  `payment_id`        CHAR(36)        NOT NULL,
  `tenant_id`         CHAR(36)        NOT NULL,
  `subscription_id`   CHAR(36)        DEFAULT NULL,
  `invoice_id`        CHAR(36)        DEFAULT NULL,
  `amount`            DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `currency`          CHAR(3)         NOT NULL DEFAULT 'EGP',
  `payment_method_id` TINYINT         DEFAULT NULL,
  `status`            TINYINT         NOT NULL DEFAULT 1 COMMENT '1=pending | 2=success | 3=failed',
  `paid_at`           TIMESTAMP       NULL DEFAULT NULL,
  `created_at`        TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`        TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`payment_id`),
  KEY `payments_tenant_idx`           (`tenant_id`),
  KEY `payments_invoice_id_fk`        (`invoice_id`),
  KEY `payments_payment_method_id_fk` (`payment_method_id`),
  CONSTRAINT `central_payments_invoice_foreign`
    FOREIGN KEY (`invoice_id`)        REFERENCES `invoices`        (`invoice_id`) ON DELETE SET NULL,
  CONSTRAINT `central_payments_method_foreign`
    FOREIGN KEY (`payment_method_id`) REFERENCES `payment_methods` (`payment_method_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Central SaaS billing payments.';

CREATE TABLE `payment_transactions` (
  `transaction_id`         CHAR(36)        NOT NULL,
  `payment_id`             CHAR(36)        NOT NULL,
  `invoice_id`             CHAR(36)        DEFAULT NULL,
  `tenant_id`              CHAR(36)        NOT NULL,
  `amount`                 DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `currency`               CHAR(3)         NOT NULL DEFAULT 'EGP',
  `payment_method_id`      TINYINT         DEFAULT NULL,
  `status`                 TINYINT         NOT NULL DEFAULT 1 COMMENT '1=pending | 2=success | 3=failed',
  `gateway_name`           VARCHAR(100)    DEFAULT NULL,
  `gateway_transaction_id` VARCHAR(255)    DEFAULT NULL,
  `gateway_response`       JSON            DEFAULT NULL,
  `ip_address`             VARBINARY(16)   DEFAULT NULL,
  `attempted_at`           TIMESTAMP       NULL DEFAULT NULL,
  `paid_at`                TIMESTAMP       NULL DEFAULT NULL,
  `failed_at`              TIMESTAMP       NULL DEFAULT NULL,
  `failure_reason`         VARCHAR(500)    DEFAULT NULL,
  `created_at`             TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`transaction_id`),
  KEY `pt_central_tenant_status_idx`    (`tenant_id`, `status`),
  KEY `pt_central_payment_fk`           (`payment_id`),
  KEY `pt_central_invoice_fk`           (`invoice_id`),
  KEY `pt_central_method_fk`            (`payment_method_id`),
  CONSTRAINT `pt_central_payment_foreign`
    FOREIGN KEY (`payment_id`)        REFERENCES `payments`        (`payment_id`),
  CONSTRAINT `pt_central_invoice_foreign`
    FOREIGN KEY (`invoice_id`)        REFERENCES `invoices`        (`invoice_id`) ON DELETE SET NULL,
  CONSTRAINT `pt_central_method_foreign`
    FOREIGN KEY (`payment_method_id`) REFERENCES `payment_methods` (`payment_method_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Individual gateway transaction attempts for central billing payments.';

CREATE TABLE `refunds` (
  `refund_id`        CHAR(36)        NOT NULL,
  `transaction_id`   CHAR(36)        NOT NULL,
  `payment_id`       CHAR(36)        NOT NULL,
  `invoice_id`       CHAR(36)        DEFAULT NULL,
  `amount`           DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `reason`           TINYINT         DEFAULT NULL COMMENT '1=duplicate | 2=fraudulent | 3=requested_by_customer | 4=other',
  `notes`            TEXT            DEFAULT NULL,
  `refunded_by`      CHAR(36)        DEFAULT NULL COMMENT 'platform_users.id',
  `gateway_refund_id` VARCHAR(255)   DEFAULT NULL,
  `status`           TINYINT         NOT NULL DEFAULT 1 COMMENT '1=pending | 2=processed | 3=failed',
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `processed_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`refund_id`),
  KEY `refunds_transaction_fk` (`transaction_id`),
  KEY `refunds_payment_fk`     (`payment_id`),
  KEY `refunds_invoice_fk`     (`invoice_id`),
  CONSTRAINT `refunds_transaction_foreign`
    FOREIGN KEY (`transaction_id`) REFERENCES `payment_transactions` (`transaction_id`),
  CONSTRAINT `refunds_payment_foreign`
    FOREIGN KEY (`payment_id`)     REFERENCES `payments`             (`payment_id`),
  CONSTRAINT `refunds_invoice_foreign`
    FOREIGN KEY (`invoice_id`)     REFERENCES `invoices`             (`invoice_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────
--  CENTRAL · LEAD CAPTURE
-- ─────────────────────────────────────────────────────────
CREATE TABLE `contact_requests` (
  `id`         CHAR(36)        NOT NULL,
  `name`       VARCHAR(255)    NOT NULL,
  `email`      VARCHAR(255)    NOT NULL,
  `phone`      VARCHAR(50)     DEFAULT NULL,
  `company`    VARCHAR(255)    DEFAULT NULL,
  `message`    TEXT            DEFAULT NULL,
  `is_handled` TINYINT(1)      NOT NULL DEFAULT 0,
  `handled_by` CHAR(36)        DEFAULT NULL COMMENT 'platform_users.id',
  `handled_at` TIMESTAMP       NULL DEFAULT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `contact_requests_is_handled_idx` (`is_handled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Inbound contact form submissions from the marketing site.';

CREATE TABLE `demo_requests` (
  `id`           CHAR(36)        NOT NULL,
  `name`         VARCHAR(255)    NOT NULL,
  `email`        VARCHAR(255)    NOT NULL,
  `phone`        VARCHAR(50)     DEFAULT NULL,
  `company`      VARCHAR(255)    DEFAULT NULL,
  `company_size` VARCHAR(50)     DEFAULT NULL,
  `notes`        TEXT            DEFAULT NULL,
  `is_handled`   TINYINT(1)      NOT NULL DEFAULT 0,
  `handled_by`   CHAR(36)        DEFAULT NULL COMMENT 'platform_users.id',
  `handled_at`   TIMESTAMP       NULL DEFAULT NULL,
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `demo_requests_is_handled_idx` (`is_handled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Demo booking requests from the marketing site.';

-- ─────────────────────────────────────────────────────────
--  CENTRAL · PLATFORM NOTIFICATIONS
-- ─────────────────────────────────────────────────────────
CREATE TABLE `platform_notifications` (
  `id`           CHAR(36)        NOT NULL,
  `title_en`     VARCHAR(255)    NOT NULL,
  `title_ar`     VARCHAR(255)    NOT NULL,
  `body_en`      TEXT            NOT NULL,
  `body_ar`      TEXT            NOT NULL,
  `type`         TINYINT         NOT NULL DEFAULT 1 COMMENT '1=info | 2=warning | 3=critical | 4=maintenance',
  `target`       TINYINT         NOT NULL DEFAULT 1 COMMENT '1=all_tenants | 2=specific_tenants | 3=specific_plans',
  `scheduled_at` TIMESTAMP       NULL DEFAULT NULL,
  `sent_at`      TIMESTAMP       NULL DEFAULT NULL,
  `created_by`   CHAR(36)        DEFAULT NULL COMMENT 'platform_users.id',
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `pn_type_idx` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Cross-tenant platform announcements (maintenance windows, feature releases).';

CREATE TABLE `platform_notification_targets` (
  `id`                       CHAR(36)        NOT NULL,
  `platform_notification_id` CHAR(36)        NOT NULL,
  `tenant_id`                CHAR(36)        NOT NULL,
  `status`                   TINYINT         NOT NULL DEFAULT 1 COMMENT '1=pending | 2=delivered | 3=read',
  `delivered_at`             TIMESTAMP       NULL DEFAULT NULL,
  `read_at`                  TIMESTAMP       NULL DEFAULT NULL,
  `created_at`               TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pnt_notification_tenant_unique` (`platform_notification_id`, `tenant_id`),
  KEY `pnt_tenant_status_idx`            (`tenant_id`, `status`),
  CONSTRAINT `pnt_notification_foreign`
    FOREIGN KEY (`platform_notification_id`) REFERENCES `platform_notifications` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pnt_tenant_foreign`
    FOREIGN KEY (`tenant_id`)               REFERENCES `tenants`                (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Delivery tracking per tenant for platform notifications.';

-- ─────────────────────────────────────────────────────────
--  CENTRAL · AUDIT LOG
-- ─────────────────────────────────────────────────────────
CREATE TABLE `audit_logs` (
  `id`           CHAR(36)        NOT NULL,
  `actor_type`   VARCHAR(50)     NOT NULL DEFAULT 'platform_user' COMMENT 'platform_user | system',
  `actor_id`     CHAR(36)        DEFAULT NULL COMMENT 'platform_users.id',
  `tenant_id`    CHAR(36)        DEFAULT NULL COMMENT 'NULL = platform-level event',
  `event`        VARCHAR(100)    NOT NULL COMMENT 'tenant.provisioned | subscription.cancelled | plan.changed',
  `subject_type` VARCHAR(100)    DEFAULT NULL,
  `subject_id`   CHAR(36)        DEFAULT NULL,
  `properties`   JSON            DEFAULT NULL COMMENT 'Before/after diff',
  `ip_address`   VARCHAR(45)     DEFAULT NULL,
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `audit_logs_tenant_idx` (`tenant_id`),
  KEY `audit_logs_event_idx`  (`event`),
  KEY `audit_logs_actor_idx`  (`actor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Central audit log for platform-level events (provisioning, billing, plan changes).';

-- ─────────────────────────────────────────────────────────
--  TENANT SETTINGS (one row per tenant)
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
  `allow_negative_stock`             TINYINT(1)      NOT NULL DEFAULT 0,
  -- printing
  `thermal_printing`                 TINYINT(1)      NOT NULL DEFAULT 0,
  `classic_printing`                 TINYINT(1)      NOT NULL DEFAULT 1,
  -- invoice & catalog display flags
  `invoice_display`                  JSON            NOT NULL DEFAULT ('{}'),
  `catalog_display`                  JSON            NOT NULL DEFAULT ('{}'),
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
  PRIMARY KEY (`id`),
  UNIQUE KEY `tenant_settings_tenant_id_unique` (`tenant_id`),
  CONSTRAINT `tenant_settings_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='All per-tenant global configuration. One row per tenant.';


-- ============================================================
--  MODULE 01 · LOCATION  (shared reference — no tenant_id)
-- ============================================================

CREATE TABLE `governorates` (
  `id`                  CHAR(36)        NOT NULL,
  `governorate_name_ar` VARCHAR(255)    NOT NULL,
  `governorate_name_en` VARCHAR(255)    NOT NULL,
  `created_at`          TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Egyptian governorates. Shared reference — no tenant_id.';

CREATE TABLE `cities` (
  `id`             CHAR(36)        NOT NULL,
  `governorate_id` CHAR(36)        NOT NULL,
  `city_name_ar`   VARCHAR(255)    NOT NULL,
  `city_name_en`   VARCHAR(255)    NOT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cities_governorate_id_fk` (`governorate_id`),
  CONSTRAINT `cities_governorate_id_foreign`
    FOREIGN KEY (`governorate_id`) REFERENCES `governorates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
--  MODULE 02 · AUTH — USERS & BRANCHES
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
  `cash_account_id`   CHAR(36)        DEFAULT NULL COMMENT 'Deferred FK → accounts',
  `credit_account_id` CHAR(36)        DEFAULT NULL COMMENT 'Deferred FK → accounts',
  `created_at`        TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`        TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`        TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `branches_tenant_id_idx`     (`tenant_id`),
  KEY `branches_governorate_id_fk` (`governorate_id`),
  KEY `branches_city_id_fk`        (`city_id`),
  CONSTRAINT `branches_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)      REFERENCES `tenants`      (`id`) ON DELETE CASCADE,
  CONSTRAINT `branches_governorate_id_foreign`
    FOREIGN KEY (`governorate_id`) REFERENCES `governorates` (`id`) ON DELETE SET NULL,
  CONSTRAINT `branches_city_id_foreign`
    FOREIGN KEY (`city_id`)        REFERENCES `cities`       (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Physical branches / locations per tenant.';

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
  `fcm_token`     VARCHAR(500)    DEFAULT NULL COMMENT 'Firebase Cloud Messaging token for push notifications',
  `is_active`     TINYINT(1)      NOT NULL DEFAULT 1,
  `last_login_at` TIMESTAMP       NULL DEFAULT NULL,
  `verified_at`   TIMESTAMP       NULL DEFAULT NULL,
  `created_at`    TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_tenant_username_unique` (`tenant_id`, `username`),
  UNIQUE KEY `users_tenant_email_unique`    (`tenant_id`, `email`),
  KEY `users_tenant_id_idx`     (`tenant_id`),
  KEY `users_branch_id_fk`      (`branch_id`),
  CONSTRAINT `users_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `users_branch_id_foreign`
    FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `password_resets` (
  `id`         CHAR(36)        NOT NULL,
  `email`      VARCHAR(255)    NOT NULL,
  `token`      VARCHAR(255)    NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `expires_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `password_resets_email_idx` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Password reset tokens. JWT is stateless; no server-session table needed.';

CREATE TABLE `user_branches` (
  `user_id`    CHAR(36)        NOT NULL,
  `branch_id`  CHAR(36)        NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`user_id`, `branch_id`),
  KEY `user_branches_branch_id_fk` (`branch_id`),
  CONSTRAINT `user_branches_user_id_foreign`
    FOREIGN KEY (`user_id`)   REFERENCES `users`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_branches_branch_id_foreign`
    FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Users can cover multiple branches.';


-- ============================================================
--  MODULE 03 · ROLES & PERMISSIONS  (Spatie — tenant-scoped)
-- ============================================================

CREATE TABLE `roles` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `name_en`        VARCHAR(255)    NOT NULL,
  `name_ar`        VARCHAR(255)    NOT NULL,
  `guard_name`     VARCHAR(50)     NOT NULL DEFAULT 'api',
  `display_name_en` VARCHAR(255)   DEFAULT NULL,
  `display_name_ar` VARCHAR(255)   DEFAULT NULL,
  `description_en` VARCHAR(500)    DEFAULT NULL,
  `description_ar` VARCHAR(500)    DEFAULT NULL,
  `is_system`      TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = cannot be deleted',
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `roles_tenant_name_guard_unique` (`tenant_id`, `name_en`, `guard_name`),
  KEY `roles_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `roles_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Spatie roles scoped per tenant.';

CREATE TABLE `permissions` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL DEFAULT 'central' COMMENT 'central = global default; else tenant-specific',
  `name_en`        VARCHAR(255)    NOT NULL COMMENT 'e.g. contact.create | sale.delete',
  `name_ar`        VARCHAR(255)    NOT NULL,
  `guard_name`     VARCHAR(50)     NOT NULL DEFAULT 'api',
  `module`         VARCHAR(100)    DEFAULT NULL COMMENT 'sales | inventory | finance | hr | crm',
  `display_name_en` VARCHAR(255)   DEFAULT NULL,
  `display_name_ar` VARCHAR(255)   DEFAULT NULL,
  `description_en` VARCHAR(500)    DEFAULT NULL,
  `description_ar` VARCHAR(500)    DEFAULT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `permissions_tenant_name_guard_unique` (`tenant_id`, `name_en`, `guard_name`),
  KEY `permissions_tenant_id_idx` (`tenant_id`),
  KEY `permissions_module_idx`    (`module`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-tenant permission definitions. tenant_id=central for global defaults seeded on provisioning.';

CREATE TABLE `role_has_permissions` (
  `id`            CHAR(36)        NOT NULL,
  `tenant_id`     CHAR(36)        NOT NULL,
  `permission_id` CHAR(36)        NOT NULL,
  `role_id`       CHAR(36)        NOT NULL,
  `created_at`    TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rhp_tenant_role_permission_unique` (`tenant_id`, `role_id`, `permission_id`),
  KEY `rhp_role_id_fk`       (`role_id`),
  KEY `rhp_permission_id_fk` (`permission_id`),
  CONSTRAINT `rhp_permission_id_foreign`
    FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `rhp_role_id_foreign`
    FOREIGN KEY (`role_id`)       REFERENCES `roles`       (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `model_has_roles` (
  `id`         CHAR(36)        NOT NULL,
  `role_id`    CHAR(36)        NOT NULL,
  `model_type` VARCHAR(255)    NOT NULL,
  `model_id`   CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mhr_model_role_tenant_unique` (`model_id`, `model_type`, `role_id`, `tenant_id`),
  KEY `mhr_role_id_fk`        (`role_id`),
  KEY `mhr_tenant_model_idx`  (`tenant_id`, `model_id`, `model_type`),
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
  PRIMARY KEY (`id`),
  UNIQUE KEY `mhp_model_permission_tenant_unique` (`model_id`, `model_type`, `permission_id`, `tenant_id`),
  KEY `mhp_permission_id_fk`   (`permission_id`),
  KEY `mhp_tenant_model_idx`   (`tenant_id`, `model_id`, `model_type`),
  CONSTRAINT `mhp_permission_id_foreign`
    FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
--  MODULE 04 · CRM — CONTACTS
-- ============================================================

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

CREATE TABLE `sales_segments` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `name_en`        VARCHAR(255)    NOT NULL,
  `name_ar`        VARCHAR(255)    NOT NULL,
  `description_en` VARCHAR(500)    DEFAULT NULL,
  `description_ar` VARCHAR(500)    DEFAULT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sales_segments_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `sales_segments_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `contact_groups` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `name_en`    VARCHAR(255)    NOT NULL,
  `name_ar`    VARCHAR(255)    NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `contact_groups_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `contact_groups_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Customer/supplier grouping tags.';

CREATE TABLE `contacts` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `type`             TINYINT         NOT NULL DEFAULT 1 COMMENT '1=customer | 2=supplier | 3=both',
  `name_en`          VARCHAR(255)    NOT NULL,
  `name_ar`          VARCHAR(255)    NOT NULL,
  `code`             VARCHAR(50)     DEFAULT NULL,
  `contact_code`     VARCHAR(50)     DEFAULT NULL,
  `tax_number`       VARCHAR(100)    DEFAULT NULL,
  `national_id`      VARCHAR(50)     DEFAULT NULL,
  `contact_person`   VARCHAR(255)    DEFAULT NULL,
  `phone`            VARCHAR(50)     DEFAULT NULL,
  `email`            VARCHAR(255)    DEFAULT NULL,
  `address`          TEXT            DEFAULT NULL,
  `latitude`         DECIMAL(10,7)   DEFAULT NULL,
  `longitude`        DECIMAL(10,7)   DEFAULT NULL,
  `governorate_id`   CHAR(36)        DEFAULT NULL,
  `city_id`          CHAR(36)        DEFAULT NULL,
  `activity_type_id` CHAR(36)        DEFAULT NULL,
  `sales_segment_id` CHAR(36)        DEFAULT NULL,
  `contact_group_id` CHAR(36)        DEFAULT NULL,
  `assigned_to`      CHAR(36)        DEFAULT NULL COMMENT 'Sales rep user_id',
  `balance`          DECIMAL(15,4)   NOT NULL DEFAULT 0.0000 COMMENT 'Denormalized cache — derived from payment_transactions',
  `opening_balance`  DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `credit_limit`     DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `is_active`        TINYINT(1)      NOT NULL DEFAULT 1,
  `is_default`       TINYINT(1)      NOT NULL DEFAULT 0,
  `tags`             JSON            DEFAULT NULL,
  `notes`            TEXT            DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `contacts_contact_code_tenant_unique` (`tenant_id`, `contact_code`),
  UNIQUE KEY `contacts_email_tenant_unique`         (`tenant_id`, `email`),
  KEY `contacts_tenant_type_idx`      (`tenant_id`, `type`),
  KEY `contacts_tenant_segment_idx`   (`tenant_id`, `sales_segment_id`),
  KEY `contacts_governorate_id_fk`    (`governorate_id`),
  KEY `contacts_city_id_fk`           (`city_id`),
  KEY `contacts_activity_type_id_fk`  (`activity_type_id`),
  KEY `contacts_sales_segment_id_fk`  (`sales_segment_id`),
  KEY `contacts_contact_group_id_fk`  (`contact_group_id`),
  KEY `contacts_assigned_to_fk`       (`assigned_to`),
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
  CONSTRAINT `contacts_contact_group_id_foreign`
    FOREIGN KEY (`contact_group_id`)  REFERENCES `contact_groups` (`id`) ON DELETE SET NULL,
  CONSTRAINT `contacts_assigned_to_foreign`
    FOREIGN KEY (`assigned_to`)       REFERENCES `users`          (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Unified customers & suppliers.';

CREATE TABLE `contact_notes` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `contact_id` CHAR(36)        NOT NULL,
  `note`       TEXT            NOT NULL,
  `created_by` CHAR(36)        NOT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `contact_notes_tenant_contact_idx` (`tenant_id`, `contact_id`),
  KEY `contact_notes_created_by_fk`      (`created_by`),
  CONSTRAINT `contact_notes_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `contact_notes_contact_id_foreign`
    FOREIGN KEY (`contact_id`) REFERENCES `contacts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `contact_notes_created_by_foreign`
    FOREIGN KEY (`created_by`) REFERENCES `users`    (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `contact_addresses` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `contact_id`     CHAR(36)        NOT NULL,
  `label`          VARCHAR(100)    DEFAULT NULL COMMENT 'e.g. warehouse | headquarters | branch',
  `address`        TEXT            NOT NULL,
  `governorate_id` CHAR(36)        DEFAULT NULL,
  `city_id`        CHAR(36)        DEFAULT NULL,
  `latitude`       DECIMAL(10,7)   DEFAULT NULL,
  `longitude`      DECIMAL(10,7)   DEFAULT NULL,
  `is_default`     TINYINT(1)      NOT NULL DEFAULT 0,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `contact_addresses_tenant_contact_idx` (`tenant_id`, `contact_id`),
  CONSTRAINT `ca_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)      REFERENCES `tenants`      (`id`) ON DELETE CASCADE,
  CONSTRAINT `ca_contact_id_foreign`
    FOREIGN KEY (`contact_id`)     REFERENCES `contacts`     (`id`) ON DELETE CASCADE,
  CONSTRAINT `ca_governorate_id_foreign`
    FOREIGN KEY (`governorate_id`) REFERENCES `governorates` (`id`) ON DELETE SET NULL,
  CONSTRAINT `ca_city_id_foreign`
    FOREIGN KEY (`city_id`)        REFERENCES `cities`       (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


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

CREATE TABLE `categories` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `parent_id`  CHAR(36)        DEFAULT NULL COMMENT 'NULL = top-level category',
  `name_en`    VARCHAR(255)    NOT NULL,
  `name_ar`    VARCHAR(255)    NOT NULL,
  `sort_order` SMALLINT        NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `categories_tenant_id_idx` (`tenant_id`),
  KEY `categories_parent_id_fk`  (`parent_id`),
  CONSTRAINT `categories_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `categories_parent_id_foreign`
    FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `units` (
  `id`                   CHAR(36)        NOT NULL,
  `tenant_id`            CHAR(36)        NOT NULL,
  `actual_name_en`       VARCHAR(255)    NOT NULL,
  `actual_name_ar`       VARCHAR(255)    NOT NULL,
  `short_name_en`        VARCHAR(50)     DEFAULT NULL,
  `short_name_ar`        VARCHAR(50)     DEFAULT NULL,
  `base_unit_id`         CHAR(36)        DEFAULT NULL COMMENT 'NULL = this IS the base unit',
  `base_unit_multiplier` DECIMAL(10,4)   DEFAULT NULL COMMENT 'e.g. 12 if 1 box = 12 pieces',
  `base_unit_is_largest` TINYINT(1)      NOT NULL DEFAULT 0,
  `created_at`           TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`           TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`           TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `units_tenant_id_idx`    (`tenant_id`),
  KEY `units_base_unit_id_fk`  (`base_unit_id`),
  CONSTRAINT `units_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `units_base_unit_id_foreign`
    FOREIGN KEY (`base_unit_id`) REFERENCES `units`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `products` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `name_en`          VARCHAR(255)    NOT NULL,
  `name_ar`          VARCHAR(255)    NOT NULL,
  `sku`              VARCHAR(100)    DEFAULT NULL,
  `barcode`          VARCHAR(100)    DEFAULT NULL,
  `description_en`   TEXT            DEFAULT NULL,
  `description_ar`   TEXT            DEFAULT NULL,
  `type`             TINYINT         NOT NULL DEFAULT 1 COMMENT '1=standard | 2=variable | 3=service | 4=combo',
  `unit_id`          CHAR(36)        DEFAULT NULL COMMENT 'Base/default unit',
  `brand_id`         CHAR(36)        DEFAULT NULL,
  `category_id`      CHAR(36)        DEFAULT NULL COMMENT 'Sub-category',
  `main_category_id` CHAR(36)        DEFAULT NULL COMMENT 'Main/parent category',
  `unit_price`       DECIMAL(15,4)   NOT NULL DEFAULT 0.0000 COMMENT 'Default sale price in base unit',
  `purchase_price`   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_rate`         DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
  `enable_stock`     TINYINT(1)      NOT NULL DEFAULT 1,
  `quantity_alert`   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `min_sale`         DECIMAL(15,4)   DEFAULT NULL,
  `max_sale`         DECIMAL(15,4)   DEFAULT NULL,
  `for_sale`         TINYINT(1)      NOT NULL DEFAULT 1,
  `is_serialized`    TINYINT(1)      NOT NULL DEFAULT 0,
  `has_expiry`       TINYINT(1)      NOT NULL DEFAULT 0,
  `notes`            TEXT            DEFAULT NULL,
  `created_by`       CHAR(36)        DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `products_tenant_id_idx`       (`tenant_id`),
  KEY `products_tenant_sku_idx`      (`tenant_id`, `sku`),
  KEY `products_tenant_barcode_idx`  (`tenant_id`, `barcode`),
  KEY `products_unit_id_fk`          (`unit_id`),
  KEY `products_brand_id_fk`         (`brand_id`),
  KEY `products_category_id_fk`      (`category_id`),
  KEY `products_main_category_id_fk` (`main_category_id`),
  KEY `products_created_by_fk`       (`created_by`),
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
--  Product variants (for type=variable products)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `product_variants` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `product_id`     CHAR(36)        NOT NULL,
  `name_en`        VARCHAR(255)    NOT NULL COMMENT 'e.g. Red / Large',
  `name_ar`        VARCHAR(255)    NOT NULL,
  `sku`            VARCHAR(100)    DEFAULT NULL,
  `barcode`        VARCHAR(100)    DEFAULT NULL,
  `unit_price`     DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `purchase_price` DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `is_active`      TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `pv_tenant_product_idx`  (`tenant_id`, `product_id`),
  KEY `pv_tenant_sku_idx`      (`tenant_id`, `sku`),
  KEY `pv_product_id_fk`       (`product_id`),
  CONSTRAINT `pv_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `pv_product_id_foreign`
    FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Variants for variable products (e.g. colour/size combinations).';

CREATE TABLE `product_unit_details` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `product_id`     CHAR(36)        NOT NULL,
  `unit_id`        CHAR(36)        NOT NULL,
  `sale_price`     DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `purchase_price` DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-unit pricing per product.';

CREATE TABLE `product_price_histories` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `product_id`     CHAR(36)        NOT NULL,
  `unit_id`        CHAR(36)        NOT NULL,
  `old_unit_price` DECIMAL(15,4)   NOT NULL,
  `new_unit_price` DECIMAL(15,4)   NOT NULL,
  `changed_by`     CHAR(36)        NOT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `pph_tenant_product_idx` (`tenant_id`, `product_id`),
  KEY `pph_product_id_fk`      (`product_id`),
  KEY `pph_changed_by_fk`      (`changed_by`),
  CONSTRAINT `pph_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `pph_product_id_foreign`
    FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pph_changed_by_foreign`
    FOREIGN KEY (`changed_by`) REFERENCES `users`    (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Price change audit log per product+unit.';

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
    FOREIGN KEY (`tenant_id`)        REFERENCES `tenants`        (`id`) ON DELETE CASCADE,
  CONSTRAINT `ssp_sales_segment_id_foreign`
    FOREIGN KEY (`sales_segment_id`) REFERENCES `sales_segments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ssp_product_id_foreign`
    FOREIGN KEY (`product_id`)       REFERENCES `products`       (`id`) ON DELETE CASCADE,
  CONSTRAINT `ssp_unit_id_foreign`
    FOREIGN KEY (`unit_id`)          REFERENCES `units`          (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Segment-specific product pricing.';

CREATE TABLE `serial_numbers` (
  `id`                     CHAR(36)        NOT NULL,
  `tenant_id`              CHAR(36)        NOT NULL,
  `product_id`             CHAR(36)        NOT NULL,
  `warehouse_id`           CHAR(36)        DEFAULT NULL COMMENT 'Deferred FK → warehouses',
  `serial_no`              VARCHAR(100)    NOT NULL,
  `status`                 TINYINT         NOT NULL DEFAULT 1 COMMENT '1=available | 2=sold | 3=returned | 4=defective',
  `sold_in_transaction_id` CHAR(36)        DEFAULT NULL COMMENT 'Deferred FK → sales_transactions',
  `notes`                  TEXT            DEFAULT NULL,
  `created_at`             TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`             TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`             TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `serial_numbers_tenant_serial_unique` (`tenant_id`, `serial_no`),
  KEY `sn_tenant_product_idx` (`tenant_id`, `product_id`),
  KEY `sn_warehouse_id_fk`    (`warehouse_id`),
  CONSTRAINT `sn_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `sn_product_id_foreign`
    FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Serial numbers for is_serialized products. One row per physical unit.';

CREATE TABLE `batch_numbers` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `product_id`       CHAR(36)        NOT NULL,
  `warehouse_id`     CHAR(36)        DEFAULT NULL COMMENT 'Deferred FK → warehouses',
  `batch_no`         VARCHAR(100)    NOT NULL,
  `expiry_date`      DATE            DEFAULT NULL,
  `manufacture_date` DATE            DEFAULT NULL,
  `qty_received`     DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `qty_remaining`    DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `unit_cost`        DECIMAL(15,4)   DEFAULT NULL,
  `notes`            TEXT            DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `batch_numbers_tenant_product_batch_unique` (`tenant_id`, `product_id`, `batch_no`),
  KEY `bn_tenant_product_idx` (`tenant_id`, `product_id`),
  KEY `bn_expiry_idx`         (`tenant_id`, `expiry_date`),
  KEY `bn_warehouse_id_fk`    (`warehouse_id`),
  CONSTRAINT `bn_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `bn_product_id_foreign`
    FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Batch/lot tracking for has_expiry products. Supports FEFO inventory.';

-- ─────────────────────────────────────────────────────────
--  CUSTOM MEDIA MODULE
-- ─────────────────────────────────────────────────────────
CREATE TABLE `media_files` (
  `id`            CHAR(36)        NOT NULL,
  `tenant_id`     CHAR(36)        NOT NULL,
  `model_type`    VARCHAR(255)    NOT NULL COMMENT 'contact | product | purchase_order | expense | employee | user | tenant',
  `model_id`      CHAR(36)        NOT NULL,
  `collection`    VARCHAR(100)    NOT NULL DEFAULT 'default',
  `file_name`     VARCHAR(255)    NOT NULL,
  `original_name` VARCHAR(255)    NOT NULL,
  `mime_type`     VARCHAR(100)    DEFAULT NULL,
  `disk`          VARCHAR(50)     NOT NULL DEFAULT 'public',
  `file_path`     VARCHAR(500)    NOT NULL,
  `file_size`     BIGINT UNSIGNED NOT NULL,
  `order`         INT UNSIGNED    NOT NULL DEFAULT 0,
  `created_by`    CHAR(36)        DEFAULT NULL,
  `created_at`    TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `media_files_tenant_model_idx` (`tenant_id`, `model_type`, `model_id`),
  KEY `media_files_collection_idx`   (`tenant_id`, `collection`),
  KEY `media_files_created_by_fk`    (`created_by`),
  CONSTRAINT `mf_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `mf_created_by_foreign`
    FOREIGN KEY (`created_by`) REFERENCES `users`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Polymorphic file attachments per tenant. Never create separate attachment tables.';


-- ============================================================
--  MODULE 06 · FINANCE & ACCOUNTS
-- ============================================================

CREATE TABLE `account_types` (
  `id`             CHAR(36)        NOT NULL,
  `name_en`        VARCHAR(100)    NOT NULL COMMENT 'Asset | Liability | Equity | Revenue | Expense',
  `name_ar`        VARCHAR(100)    NOT NULL,
  `normal_balance` TINYINT         NOT NULL COMMENT '1=debit | 2=credit',
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Double-entry account type definitions. Seeded globally, not per-tenant.';

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

-- Deferred FKs: branches → accounts (accounts table now exists)
ALTER TABLE `branches`
  ADD KEY `branches_cash_account_fk`   (`cash_account_id`),
  ADD KEY `branches_credit_account_fk` (`credit_account_id`),
  ADD CONSTRAINT `branches_cash_account_id_foreign`
    FOREIGN KEY (`cash_account_id`)   REFERENCES `accounts` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `branches_credit_account_id_foreign`
    FOREIGN KEY (`credit_account_id`) REFERENCES `accounts` (`id`) ON DELETE SET NULL;

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
  KEY `coa_tenant_id_idx`       (`tenant_id`),
  KEY `coa_parent_id_fk`        (`parent_id`),
  KEY `coa_account_type_id_fk`  (`account_type_id`),
  CONSTRAINT `coa_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)       REFERENCES `tenants`           (`id`) ON DELETE CASCADE,
  CONSTRAINT `coa_parent_id_foreign`
    FOREIGN KEY (`parent_id`)       REFERENCES `chart_of_accounts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `coa_account_type_id_foreign`
    FOREIGN KEY (`account_type_id`) REFERENCES `account_types`     (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  KEY `je_tenant_date_idx` (`tenant_id`, `entry_date`),
  KEY `je_reference_idx`   (`reference_type`, `reference_id`),
  KEY `je_posted_by_fk`    (`posted_by`),
  KEY `je_created_by_fk`   (`created_by`),
  CONSTRAINT `je_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants` (`id`) ON DELETE CASCADE,
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

CREATE TABLE `taxes` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `name_en`    VARCHAR(100)    NOT NULL COMMENT 'e.g. VAT 14%, Withholding 5%',
  `name_ar`    VARCHAR(100)    NOT NULL,
  `rate`       DECIMAL(5,2)    NOT NULL,
  `type`       TINYINT         NOT NULL DEFAULT 1 COMMENT '1=percentage | 2=fixed',
  `is_active`  TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `taxes_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `taxes_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `currencies` (
  `id`              CHAR(36)        NOT NULL,
  `tenant_id`       CHAR(36)        NOT NULL,
  `code`            CHAR(3)         NOT NULL COMMENT 'ISO 4217 e.g. EGP | USD | EUR',
  `name_en`         VARCHAR(100)    NOT NULL,
  `name_ar`         VARCHAR(100)    NOT NULL,
  `symbol`          VARCHAR(10)     NOT NULL,
  `exchange_rate`   DECIMAL(15,6)   NOT NULL DEFAULT 1.000000 COMMENT 'Rate relative to base currency',
  `is_base`         TINYINT(1)      NOT NULL DEFAULT 0,
  `is_active`       TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`      TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `currencies_tenant_code_unique` (`tenant_id`, `code`),
  KEY `currencies_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `currencies_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Supported currencies per tenant with exchange rates.';

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
  `expense_date`        DATE            NOT NULL,
  `ref_no`              VARCHAR(100)    DEFAULT NULL,
  `note`                VARCHAR(500)    DEFAULT NULL,
  `created_by`          CHAR(36)        DEFAULT NULL,
  `created_at`          TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`          TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `expenses_tenant_id_idx`          (`tenant_id`),
  KEY `expenses_expense_category_id_fk` (`expense_category_id`),
  KEY `expenses_account_id_fk`          (`account_id`),
  KEY `expenses_branch_id_fk`           (`branch_id`),
  KEY `expenses_cost_center_id_fk`      (`cost_center_id`),
  KEY `expenses_created_by_fk`          (`created_by`),
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

-- ─────────────────────────────────────────────────────────
--  KEY-VALUE SETTINGS STORE  (module-level config per tenant)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `settings` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `key`        VARCHAR(150)    NOT NULL COMMENT 'format: module.setting_name — e.g. sales.invoice_prefix',
  `value`      TEXT            DEFAULT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `settings_tenant_key_unique` (`tenant_id`, `key`),
  KEY `settings_tenant_id_idx` (`tenant_id`),
  CONSTRAINT `settings_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Module-level key-value configuration per tenant. Key format: {module}.{setting_name}.';


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

-- Deferred FKs: serial_numbers and batch_numbers → warehouses
ALTER TABLE `serial_numbers`
  ADD CONSTRAINT `sn_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE SET NULL;

ALTER TABLE `batch_numbers`
  ADD CONSTRAINT `bn_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE SET NULL;

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
  PRIMARY KEY (`id`),
  UNIQUE KEY `stock_levels_unique` (`tenant_id`, `warehouse_id`, `product_id`, `unit_id`),
  KEY `stock_levels_tenant_product_idx` (`tenant_id`, `product_id`),
  KEY `stock_levels_warehouse_id_fk`    (`warehouse_id`),
  KEY `stock_levels_product_id_fk`      (`product_id`),
  KEY `stock_levels_unit_id_fk`         (`unit_id`),
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

CREATE TABLE `stock_movements` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `warehouse_id`   CHAR(36)        NOT NULL,
  `product_id`     CHAR(36)        NOT NULL,
  `unit_id`        CHAR(36)        NOT NULL,
  `reference_type` VARCHAR(50)     DEFAULT NULL COMMENT 'sales_transaction | purchase_transaction | inventory_transaction',
  `reference_id`   CHAR(36)        DEFAULT NULL,
  `movement_type`  VARCHAR(30)     NOT NULL COMMENT 'purchase | sale | sale_return | purchase_return | transfer_in | transfer_out | adjustment | opening_stock | spoilage',
  `quantity`       DECIMAL(15,4)   NOT NULL COMMENT 'Positive=in | Negative=out',
  `unit_cost`      DECIMAL(15,4)   DEFAULT NULL,
  `reference_no`   VARCHAR(100)    DEFAULT NULL,
  `batch_id`       CHAR(36)        DEFAULT NULL,
  `serial_id`      CHAR(36)        DEFAULT NULL,
  `note`           TEXT            DEFAULT NULL,
  `created_by`     CHAR(36)        DEFAULT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
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
  COMMENT='Append-only stock ledger. Never UPDATE or DELETE rows.';

CREATE TABLE `stock_adjustments` (
  `id`           CHAR(36)        NOT NULL,
  `tenant_id`    CHAR(36)        NOT NULL,
  `warehouse_id` CHAR(36)        NOT NULL,
  `ref_no`       VARCHAR(100)    DEFAULT NULL,
  `reason`       VARCHAR(500)    DEFAULT NULL,
  `status`       TINYINT         NOT NULL DEFAULT 1 COMMENT '1=draft | 2=approved | 3=rejected',
  `approved_by`  CHAR(36)        DEFAULT NULL,
  `approved_at`  TIMESTAMP       NULL DEFAULT NULL,
  `created_by`   CHAR(36)        NOT NULL,
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`   TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sa_tenant_id_idx`   (`tenant_id`),
  KEY `sa_warehouse_id_fk` (`warehouse_id`),
  KEY `sa_approved_by_fk`  (`approved_by`),
  KEY `sa_created_by_fk`   (`created_by`),
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
-- ============================================================

-- ─────────────────────────────────────────────────────────
--  8A. SALES TRANSACTIONS
-- ─────────────────────────────────────────────────────────
CREATE TABLE `sales_transactions` (
  `id`                   CHAR(36)        NOT NULL,
  `tenant_id`            CHAR(36)        NOT NULL,
  `branch_id`            CHAR(36)        DEFAULT NULL,
  `warehouse_id`         CHAR(36)        DEFAULT NULL,
  `contact_id`           CHAR(36)        DEFAULT NULL COMMENT 'Customer',
  `tax_id`               CHAR(36)        DEFAULT NULL,
  `created_by`           CHAR(36)        DEFAULT NULL,
  `return_of_id`         CHAR(36)        DEFAULT NULL COMMENT 'Original sales_transaction for returns',
  `type`                 TINYINT         NOT NULL DEFAULT 1 COMMENT '1=sell | 2=sell_return',
  `status`               TINYINT         NOT NULL DEFAULT 1 COMMENT '1=draft | 2=confirmed | 3=cancelled',
  `ref_no`               VARCHAR(100)    DEFAULT NULL,
  `transaction_date`     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `subtotal`             DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `discount_type`        TINYINT         DEFAULT NULL COMMENT '1=percentage | 2=fixed_price',
  `discount_value`       DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_amount`           DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `shipping_cost`        DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `final_price`          DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `payment_type`         TINYINT         NOT NULL DEFAULT 1 COMMENT '1=cash | 2=credit',
  `payment_status`       TINYINT         NOT NULL DEFAULT 1 COMMENT '1=due | 2=partial | 3=paid',
  `delivery_status`      TINYINT         NOT NULL DEFAULT 1 COMMENT '1=ordered | 2=shipped | 3=delivered',
  `delivery_status_note` VARCHAR(255)    DEFAULT NULL,
  `transaction_from`     VARCHAR(50)     DEFAULT NULL COMMENT 'pos | online | api',
  `pos_session_id`       CHAR(36)        DEFAULT NULL COMMENT 'Deferred FK → pos_sessions',
  `notes`                TEXT            DEFAULT NULL,
  `created_at`           TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`           TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`           TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `stx_tenant_type_idx`    (`tenant_id`, `type`),
  KEY `stx_tenant_date_idx`    (`tenant_id`, `transaction_date`),
  KEY `stx_tenant_status_idx`  (`tenant_id`, `status`),
  KEY `stx_tenant_contact_idx` (`tenant_id`, `contact_id`),
  KEY `stx_branch_id_fk`       (`branch_id`),
  KEY `stx_warehouse_id_fk`    (`warehouse_id`),
  KEY `stx_return_of_id_fk`    (`return_of_id`),
  KEY `stx_created_by_fk`      (`created_by`),
  KEY `stx_tax_id_fk`          (`tax_id`),
  CONSTRAINT `stx_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants`            (`id`) ON DELETE CASCADE,
  CONSTRAINT `stx_branch_id_foreign`
    FOREIGN KEY (`branch_id`)    REFERENCES `branches`           (`id`) ON DELETE SET NULL,
  CONSTRAINT `stx_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses`         (`id`) ON DELETE SET NULL,
  CONSTRAINT `stx_contact_id_foreign`
    FOREIGN KEY (`contact_id`)   REFERENCES `contacts`           (`id`) ON DELETE SET NULL,
  CONSTRAINT `stx_return_of_id_foreign`
    FOREIGN KEY (`return_of_id`) REFERENCES `sales_transactions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `stx_created_by_foreign`
    FOREIGN KEY (`created_by`)   REFERENCES `users`              (`id`) ON DELETE SET NULL,
  CONSTRAINT `stx_tax_id_foreign`
    FOREIGN KEY (`tax_id`)       REFERENCES `taxes`              (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Sales invoices and sales returns.';

-- ─────────────────────────────────────────────────────────
--  POS SESSIONS  (defined after sales_transactions for FK ordering)
-- ─────────────────────────────────────────────────────────
CREATE TABLE `pos_sessions` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `branch_id`        CHAR(36)        NOT NULL,
  `warehouse_id`     CHAR(36)        DEFAULT NULL,
  `user_id`          CHAR(36)        NOT NULL COMMENT 'Cashier',
  `account_id`       CHAR(36)        DEFAULT NULL COMMENT 'Cash drawer account',
  `status`           TINYINT         NOT NULL DEFAULT 1 COMMENT '1=open | 2=closed',
  `opening_cash`     DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `closing_cash`     DECIMAL(15,4)   DEFAULT NULL,
  `cash_difference`  DECIMAL(15,4)   DEFAULT NULL COMMENT 'closing_cash - expected_cash',
  `total_sales`      DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `total_returns`    DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `total_payments`   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `opened_at`        TIMESTAMP       NULL DEFAULT NULL,
  `closed_at`        TIMESTAMP       NULL DEFAULT NULL,
  `notes`            TEXT            DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `pos_tenant_id_idx`      (`tenant_id`),
  KEY `pos_branch_id_fk`       (`branch_id`),
  KEY `pos_warehouse_id_fk`    (`warehouse_id`),
  KEY `pos_user_id_fk`         (`user_id`),
  KEY `pos_account_id_fk`      (`account_id`),
  KEY `pos_status_idx`         (`tenant_id`, `status`),
  CONSTRAINT `pos_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `pos_branch_id_foreign`
    FOREIGN KEY (`branch_id`)    REFERENCES `branches`   (`id`) ON DELETE RESTRICT,
  CONSTRAINT `pos_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE SET NULL,
  CONSTRAINT `pos_user_id_foreign`
    FOREIGN KEY (`user_id`)      REFERENCES `users`      (`id`) ON DELETE RESTRICT,
  CONSTRAINT `pos_account_id_foreign`
    FOREIGN KEY (`account_id`)   REFERENCES `accounts`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='POS session per cashier shift. Each sale links to an open session.';

-- Deferred FK: sales_transactions → pos_sessions
ALTER TABLE `sales_transactions`
  ADD KEY `stx_pos_session_id_fk` (`pos_session_id`),
  ADD CONSTRAINT `stx_pos_session_id_foreign`
    FOREIGN KEY (`pos_session_id`) REFERENCES `pos_sessions` (`id`) ON DELETE SET NULL;

-- Deferred FK: serial_numbers → sales_transactions
ALTER TABLE `serial_numbers`
  ADD KEY `sn_sold_in_transaction_id_fk` (`sold_in_transaction_id`),
  ADD CONSTRAINT `sn_sold_in_transaction_id_foreign`
    FOREIGN KEY (`sold_in_transaction_id`) REFERENCES `sales_transactions` (`id`) ON DELETE SET NULL;

CREATE TABLE `sales_transaction_lines` (
  `id`                           CHAR(36)        NOT NULL,
  `tenant_id`                    CHAR(36)        NOT NULL,
  `sales_transaction_id`         CHAR(36)        NOT NULL,
  `product_id`                   CHAR(36)        NOT NULL,
  `unit_id`                      CHAR(36)        NOT NULL,
  `purchase_transaction_line_id` CHAR(36)        DEFAULT NULL COMMENT 'Deferred FK — FIFO costing link',
  `batch_id`                     CHAR(36)        DEFAULT NULL,
  `serial_id`                    CHAR(36)        DEFAULT NULL,
  `quantity`                     DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `main_unit_quantity`           DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `return_quantity`              DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `unit_price`                   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `discount`                     DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_rate`                     DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
  `total`                        DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `created_at`                   TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`                   TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`                   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `stxl_tenant_id_idx`              (`tenant_id`),
  KEY `stxl_sales_transaction_id_fk`   (`sales_transaction_id`),
  KEY `stxl_product_id_fk`             (`product_id`),
  KEY `stxl_unit_id_fk`                (`unit_id`),
  KEY `stxl_ptl_id_fk`                 (`purchase_transaction_line_id`),
  KEY `stxl_batch_id_fk`               (`batch_id`),
  KEY `stxl_serial_id_fk`              (`serial_id`),
  CONSTRAINT `stxl_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)            REFERENCES `tenants`            (`id`) ON DELETE CASCADE,
  CONSTRAINT `stxl_sales_transaction_id_foreign`
    FOREIGN KEY (`sales_transaction_id`) REFERENCES `sales_transactions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `stxl_product_id_foreign`
    FOREIGN KEY (`product_id`)           REFERENCES `products`           (`id`) ON DELETE CASCADE,
  CONSTRAINT `stxl_unit_id_foreign`
    FOREIGN KEY (`unit_id`)              REFERENCES `units`              (`id`) ON DELETE CASCADE,
  CONSTRAINT `stxl_batch_id_foreign`
    FOREIGN KEY (`batch_id`)             REFERENCES `batch_numbers`      (`id`) ON DELETE SET NULL,
  CONSTRAINT `stxl_serial_id_foreign`
    FOREIGN KEY (`serial_id`)            REFERENCES `serial_numbers`     (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Line items for sales_transactions.';

-- ─────────────────────────────────────────────────────────
--  8B. PURCHASE TRANSACTIONS
-- ─────────────────────────────────────────────────────────
CREATE TABLE `purchase_transactions` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `branch_id`        CHAR(36)        DEFAULT NULL,
  `warehouse_id`     CHAR(36)        DEFAULT NULL,
  `contact_id`       CHAR(36)        DEFAULT NULL COMMENT 'Supplier',
  `tax_id`           CHAR(36)        DEFAULT NULL,
  `purchase_order_id` CHAR(36)       DEFAULT NULL COMMENT 'Deferred FK → purchase_orders',
  `created_by`       CHAR(36)        DEFAULT NULL,
  `return_of_id`     CHAR(36)        DEFAULT NULL COMMENT 'Original purchase_transaction for returns',
  `type`             TINYINT         NOT NULL DEFAULT 1 COMMENT '1=purchase | 2=purchase_return',
  `status`           TINYINT         NOT NULL DEFAULT 1 COMMENT '1=draft | 2=confirmed | 3=cancelled',
  `ref_no`           VARCHAR(100)    DEFAULT NULL,
  `supplier_ref_no`  VARCHAR(100)    DEFAULT NULL,
  `transaction_date` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `subtotal`         DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `discount_type`    TINYINT         DEFAULT NULL COMMENT '1=percentage | 2=fixed_price',
  `discount_value`   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_amount`       DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `shipping_cost`    DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `final_price`      DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `payment_type`     TINYINT         NOT NULL DEFAULT 1 COMMENT '1=cash | 2=credit',
  `payment_status`   TINYINT         NOT NULL DEFAULT 1 COMMENT '1=due | 2=partial | 3=paid',
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
  KEY `ptx_return_of_id_fk`      (`return_of_id`),
  KEY `ptx_purchase_order_id_fk` (`purchase_order_id`),
  KEY `ptx_created_by_fk`        (`created_by`),
  KEY `ptx_tax_id_fk`            (`tax_id`),
  CONSTRAINT `ptx_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)    REFERENCES `tenants`               (`id`) ON DELETE CASCADE,
  CONSTRAINT `ptx_branch_id_foreign`
    FOREIGN KEY (`branch_id`)    REFERENCES `branches`              (`id`) ON DELETE SET NULL,
  CONSTRAINT `ptx_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses`            (`id`) ON DELETE SET NULL,
  CONSTRAINT `ptx_contact_id_foreign`
    FOREIGN KEY (`contact_id`)   REFERENCES `contacts`              (`id`) ON DELETE SET NULL,
  CONSTRAINT `ptx_return_of_id_foreign`
    FOREIGN KEY (`return_of_id`) REFERENCES `purchase_transactions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `ptx_created_by_foreign`
    FOREIGN KEY (`created_by`)   REFERENCES `users`                 (`id`) ON DELETE SET NULL,
  CONSTRAINT `ptx_tax_id_foreign`
    FOREIGN KEY (`tax_id`)       REFERENCES `taxes`                 (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Purchase invoices from suppliers and purchase returns.';

CREATE TABLE `purchase_transaction_lines` (
  `id`                      CHAR(36)        NOT NULL,
  `tenant_id`               CHAR(36)        NOT NULL,
  `purchase_transaction_id` CHAR(36)        NOT NULL,
  `product_id`              CHAR(36)        NOT NULL,
  `unit_id`                 CHAR(36)        NOT NULL,
  `batch_id`                CHAR(36)        DEFAULT NULL,
  `quantity`                DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `main_unit_quantity`      DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `return_quantity`         DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `unit_price`              DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `discount`                DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_rate`                DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
  `total`                   DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `created_at`              TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`              TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`              TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ptxl_tenant_id_idx`               (`tenant_id`),
  KEY `ptxl_purchase_transaction_id_fk`  (`purchase_transaction_id`),
  KEY `ptxl_product_id_fk`               (`product_id`),
  KEY `ptxl_unit_id_fk`                  (`unit_id`),
  KEY `ptxl_batch_id_fk`                 (`batch_id`),
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

-- Deferred FK: sales_transaction_lines → purchase_transaction_lines (FIFO costing)
ALTER TABLE `sales_transaction_lines`
  ADD CONSTRAINT `stxl_purchase_transaction_line_id_foreign`
    FOREIGN KEY (`purchase_transaction_line_id`)
      REFERENCES `purchase_transaction_lines` (`id`) ON DELETE SET NULL;

-- ─────────────────────────────────────────────────────────
--  8C. INVENTORY TRANSACTIONS
-- ─────────────────────────────────────────────────────────
CREATE TABLE `inventory_transactions` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `branch_id`        CHAR(36)        DEFAULT NULL,
  `warehouse_id`     CHAR(36)        DEFAULT NULL COMMENT 'Source warehouse',
  `warehouse_to_id`  CHAR(36)        DEFAULT NULL COMMENT 'Destination warehouse (transfers)',
  `branch_to_id`     CHAR(36)        DEFAULT NULL COMMENT 'Destination branch (transfers)',
  `created_by`       CHAR(36)        DEFAULT NULL,
  `type`             TINYINT         NOT NULL COMMENT '1=transfer | 2=opening_stock | 3=spoiled_stock | 4=adjustment',
  `status`           TINYINT         NOT NULL DEFAULT 1 COMMENT '1=draft | 2=confirmed | 3=cancelled',
  `ref_no`           VARCHAR(100)    DEFAULT NULL,
  `transaction_date` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reason`           VARCHAR(500)    DEFAULT NULL,
  `notes`            TEXT            DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `itx_tenant_type_idx`    (`tenant_id`, `type`),
  KEY `itx_tenant_date_idx`    (`tenant_id`, `transaction_date`),
  KEY `itx_branch_id_fk`       (`branch_id`),
  KEY `itx_warehouse_id_fk`    (`warehouse_id`),
  KEY `itx_warehouse_to_id_fk` (`warehouse_to_id`),
  KEY `itx_branch_to_id_fk`    (`branch_to_id`),
  KEY `itx_created_by_fk`      (`created_by`),
  CONSTRAINT `itx_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)       REFERENCES `tenants`    (`id`) ON DELETE CASCADE,
  CONSTRAINT `itx_branch_id_foreign`
    FOREIGN KEY (`branch_id`)       REFERENCES `branches`   (`id`) ON DELETE SET NULL,
  CONSTRAINT `itx_warehouse_id_foreign`
    FOREIGN KEY (`warehouse_id`)    REFERENCES `warehouses` (`id`) ON DELETE SET NULL,
  CONSTRAINT `itx_warehouse_to_id_foreign`
    FOREIGN KEY (`warehouse_to_id`) REFERENCES `warehouses` (`id`) ON DELETE SET NULL,
  CONSTRAINT `itx_branch_to_id_foreign`
    FOREIGN KEY (`branch_to_id`)    REFERENCES `branches`   (`id`) ON DELETE SET NULL,
  CONSTRAINT `itx_created_by_foreign`
    FOREIGN KEY (`created_by`)      REFERENCES `users`      (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Inventory movements: transfers, opening stock, spoilage, manual adjustments.';

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
  `qty_system`               DECIMAL(15,4)   DEFAULT NULL COMMENT 'For adjustment type only',
  `qty_actual`               DECIMAL(15,4)   DEFAULT NULL COMMENT 'For adjustment type only',
  `unit_cost`                DECIMAL(15,4)   DEFAULT NULL,
  `reason`                   VARCHAR(500)    DEFAULT NULL,
  `created_at`               TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`               TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`               TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `itxl_tenant_id_idx`                  (`tenant_id`),
  KEY `itxl_inventory_transaction_id_fk`    (`inventory_transaction_id`),
  KEY `itxl_product_id_fk`                  (`product_id`),
  KEY `itxl_unit_id_fk`                     (`unit_id`),
  KEY `itxl_batch_id_fk`                    (`batch_id`),
  KEY `itxl_serial_id_fk`                   (`serial_id`),
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `transaction_update_histories` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `transaction_type` TINYINT         NOT NULL COMMENT '1=sales | 2=purchase | 3=inventory',
  `transaction_id`   CHAR(36)        NOT NULL,
  `old_total`        DECIMAL(15,4)   NOT NULL,
  `new_total`        DECIMAL(15,4)   NOT NULL,
  `old_final_price`  DECIMAL(15,4)   NOT NULL,
  `new_final_price`  DECIMAL(15,4)   NOT NULL,
  `changes_summary`  JSON            DEFAULT NULL,
  `updated_by`       CHAR(36)        NOT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tuh_tenant_transaction_idx` (`tenant_id`, `transaction_id`),
  KEY `tuh_updated_by_fk`          (`updated_by`),
  CONSTRAINT `tuh_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tuh_updated_by_foreign`
    FOREIGN KEY (`updated_by`) REFERENCES `users`   (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Audit log for edits across all three transaction tables.';


-- ============================================================
--  MODULE 09 · PAYMENTS (tenant-level)
-- ============================================================

CREATE TABLE `tenant_payments` (
  `id`         CHAR(36)        NOT NULL,
  `tenant_id`  CHAR(36)        NOT NULL,
  `contact_id` CHAR(36)        DEFAULT NULL,
  `account_id` CHAR(36)        DEFAULT NULL,
  `amount`     DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `method`     VARCHAR(50)     NOT NULL DEFAULT 'cash' COMMENT 'cash | bank_transfer | check | card',
  `operation`  TINYINT         NOT NULL DEFAULT 1 COMMENT '1=add | 2=subtract',
  `type`       VARCHAR(100)    DEFAULT NULL COMMENT 'payment classification label',
  `for`        VARCHAR(255)    DEFAULT NULL COMMENT 'free-text description',
  `created_by` CHAR(36)        DEFAULT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
  `updated_at` TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tp_tenant_id_idx`   (`tenant_id`),
  KEY `tp_contact_id_fk`   (`contact_id`),
  KEY `tp_account_id_fk`   (`account_id`),
  KEY `tp_created_by_fk`   (`created_by`),
  CONSTRAINT `tp_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `tp_contact_id_foreign`
    FOREIGN KEY (`contact_id`) REFERENCES `contacts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tp_account_id_foreign`
    FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tp_created_by_foreign`
    FOREIGN KEY (`created_by`) REFERENCES `users`    (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Standalone open payments (prepayments not tied to a single invoice).';

CREATE TABLE `tenant_payment_transactions` (
  `id`               CHAR(36)        NOT NULL,
  `tenant_id`        CHAR(36)        NOT NULL,
  `transaction_type` TINYINT         NOT NULL COMMENT '1=sales | 2=purchase',
  `transaction_id`   CHAR(36)        NOT NULL COMMENT 'Polymorphic → sales_transactions or purchase_transactions',
  `payment_id`       CHAR(36)        DEFAULT NULL COMMENT 'Links to tenant_payments if settling an open payment',
  `contact_id`       CHAR(36)        DEFAULT NULL,
  `account_id`       CHAR(36)        DEFAULT NULL,
  `amount`           DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `method`           VARCHAR(50)     NOT NULL DEFAULT 'cash',
  `operation`        TINYINT         NOT NULL DEFAULT 1 COMMENT '1=add | 2=subtract',
  `created_by`       CHAR(36)        DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_tenant_id_idx`      (`tenant_id`),
  KEY `tpt_transaction_idx`    (`transaction_type`, `transaction_id`),
  KEY `tpt_payment_id_fk`      (`payment_id`),
  KEY `tpt_contact_id_fk`      (`contact_id`),
  KEY `tpt_account_id_fk`      (`account_id`),
  KEY `tpt_created_by_fk`      (`created_by`),
  CONSTRAINT `tpt_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants`          (`id`) ON DELETE CASCADE,
  CONSTRAINT `tpt_payment_id_foreign`
    FOREIGN KEY (`payment_id`) REFERENCES `tenant_payments`  (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_contact_id_foreign`
    FOREIGN KEY (`contact_id`) REFERENCES `contacts`         (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_account_id_foreign`
    FOREIGN KEY (`account_id`) REFERENCES `accounts`         (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_created_by_foreign`
    FOREIGN KEY (`created_by`) REFERENCES `users`            (`id`) ON DELETE SET NULL
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
  `status`                      TINYINT         NOT NULL DEFAULT 1 COMMENT '1=draft | 2=sent | 3=accepted | 4=rejected | 5=converted',
  `total`                       DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `discount_type`               TINYINT         DEFAULT NULL COMMENT '1=percentage | 2=fixed',
  `discount_value`              DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `tax_amount`                  DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `final_price`                 DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `notes`                       TEXT            DEFAULT NULL,
  `converted_to_transaction_id` CHAR(36)        DEFAULT NULL,
  `created_by`                  CHAR(36)        NOT NULL,
  `created_at`                  TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`                  TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`                  TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `q_tenant_id_idx`                   (`tenant_id`),
  KEY `q_branch_id_fk`                    (`branch_id`),
  KEY `q_contact_id_fk`                   (`contact_id`),
  KEY `q_converted_to_transaction_id_fk`  (`converted_to_transaction_id`),
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
  `total`            DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `status`           TINYINT         NOT NULL DEFAULT 1 COMMENT '1=pending | 2=confirmed | 3=cancelled | 4=converted',
  `converted_to_transaction_id` CHAR(36) DEFAULT NULL,
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
    FOREIGN KEY (`converted_to_transaction_id`) REFERENCES `sales_transactions` (`id`) ON DELETE SET NULL,
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
  `status`        TINYINT         NOT NULL DEFAULT 1 COMMENT '1=draft | 2=sent | 3=partial | 4=received | 5=cancelled',
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
  KEY `po_tenant_id_idx`   (`tenant_id`),
  KEY `po_branch_id_fk`    (`branch_id`),
  KEY `po_warehouse_id_fk` (`warehouse_id`),
  KEY `po_contact_id_fk`   (`contact_id`),
  KEY `po_created_by_fk`   (`created_by`),
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

-- Deferred FK: purchase_transactions → purchase_orders
ALTER TABLE `purchase_transactions`
  ADD CONSTRAINT `ptx_purchase_order_id_foreign`
    FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE SET NULL;


-- ============================================================
--  MODULE 12 · CRM — LEADS & ACTIVITIES
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
  `source`              TINYINT         DEFAULT NULL COMMENT '1=website | 2=referral | 3=social | 4=cold_call | 5=exhibition | 6=other',
  `status`              TINYINT         NOT NULL DEFAULT 1 COMMENT '1=new | 2=contacted | 3=qualified | 4=proposal | 5=negotiation | 6=won | 7=lost',
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
  `type`         TINYINT         NOT NULL COMMENT '1=call | 2=meeting | 3=email | 4=note | 5=task',
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
  KEY `crma_tenant_id_idx`  (`tenant_id`),
  KEY `crma_lead_id_fk`     (`lead_id`),
  KEY `crma_contact_id_fk`  (`contact_id`),
  KEY `crma_assigned_to_fk` (`assigned_to`),
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
  `manager_id` CHAR(36)        DEFAULT NULL COMMENT 'Deferred FK → employees',
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
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `department_id`  CHAR(36)        DEFAULT NULL,
  `title_en`       VARCHAR(255)    NOT NULL,
  `title_ar`       VARCHAR(255)    NOT NULL,
  `description_en` TEXT            DEFAULT NULL,
  `description_ar` TEXT            DEFAULT NULL,
  `min_salary`     DECIMAL(15,4)   DEFAULT NULL,
  `max_salary`     DECIMAL(15,4)   DEFAULT NULL,
  `is_active`      TINYINT(1)      NOT NULL DEFAULT 1,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `jp_tenant_id_idx`    (`tenant_id`),
  KEY `jp_department_id_fk` (`department_id`),
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
  `gender`           TINYINT         DEFAULT NULL COMMENT '1=male | 2=female',
  `birth_date`       DATE            DEFAULT NULL,
  `hire_date`        DATE            NOT NULL,
  `termination_date` DATE            DEFAULT NULL,
  `employment_type`  TINYINT         NOT NULL DEFAULT 1 COMMENT '1=full_time | 2=part_time | 3=contractor | 4=intern',
  `status`           TINYINT         NOT NULL DEFAULT 1 COMMENT '1=active | 2=inactive | 3=on_leave | 4=terminated',
  `email`            VARCHAR(255)    DEFAULT NULL,
  `phone`            VARCHAR(50)     DEFAULT NULL,
  `address`          TEXT            DEFAULT NULL,
  `governorate_id`   CHAR(36)        DEFAULT NULL,
  `city_id`          CHAR(36)        DEFAULT NULL,
  `bank_account_no`  VARCHAR(100)    DEFAULT NULL,
  `bank_name`        VARCHAR(255)    DEFAULT NULL,
  `base_salary`      DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `salary_type`      TINYINT         NOT NULL DEFAULT 1 COMMENT '1=monthly | 2=daily | 3=hourly',
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

-- Deferred FK: departments.manager_id → employees
ALTER TABLE `departments`
  ADD KEY `dept_manager_id_fk` (`manager_id`),
  ADD CONSTRAINT `dept_manager_id_foreign`
    FOREIGN KEY (`manager_id`) REFERENCES `employees` (`id`) ON DELETE SET NULL;

CREATE TABLE `attendance_logs` (
  `id`             CHAR(36)        NOT NULL,
  `tenant_id`      CHAR(36)        NOT NULL,
  `employee_id`    CHAR(36)        NOT NULL,
  `date`           DATE            NOT NULL,
  `check_in`       TIMESTAMP       NULL DEFAULT NULL,
  `check_out`      TIMESTAMP       NULL DEFAULT NULL,
  `status`         TINYINT         NOT NULL DEFAULT 1 COMMENT '1=present | 2=absent | 3=late | 4=half_day | 5=leave',
  `overtime_hours` DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
  `note`           TEXT            DEFAULT NULL,
  `created_at`     TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`     TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`     TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `attendance_employee_date_unique` (`tenant_id`, `employee_id`, `date`),
  KEY `att_tenant_date_idx`  (`tenant_id`, `date`),
  KEY `att_employee_id_fk`   (`employee_id`),
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
  `status`         TINYINT         NOT NULL DEFAULT 1 COMMENT '1=pending | 2=approved | 3=rejected',
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
  `type`        TINYINT         NOT NULL COMMENT '1=allowance | 2=deduction',
  `calculation` TINYINT         NOT NULL DEFAULT 1 COMMENT '1=fixed | 2=percentage',
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
  `status`           TINYINT         NOT NULL DEFAULT 1 COMMENT '1=draft | 2=approved | 3=paid',
  `total_gross`      DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `total_net`        DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `total_deductions` DECIMAL(15,4)   NOT NULL DEFAULT 0.0000,
  `processed_by`     CHAR(36)        DEFAULT NULL,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`       TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `pp_tenant_id_idx`   (`tenant_id`),
  KEY `pp_processed_by_fk` (`processed_by`),
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
  `payment_method`    TINYINT         NOT NULL DEFAULT 1 COMMENT '1=bank_transfer | 2=cash | 3=check',
  `paid_at`           TIMESTAMP       NULL DEFAULT NULL,
  `lines`             JSON            DEFAULT NULL COMMENT 'Breakdown of salary components',
  `created_at`        TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`        TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`        TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `payroll_slips_period_employee_unique` (`tenant_id`, `payroll_period_id`, `employee_id`),
  KEY `ps_tenant_id_idx`        (`tenant_id`),
  KEY `ps_payroll_period_id_fk` (`payroll_period_id`),
  KEY `ps_employee_id_fk`       (`employee_id`),
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
    FOREIGN KEY (`tenant_id`)  REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `rt_created_by_foreign`
    FOREIGN KEY (`created_by`) REFERENCES `users`   (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `scheduled_reports` (
  `id`                 CHAR(36)        NOT NULL,
  `tenant_id`          CHAR(36)        NOT NULL,
  `report_template_id` CHAR(36)        DEFAULT NULL,
  `name_en`            VARCHAR(255)    NOT NULL,
  `name_ar`            VARCHAR(255)    NOT NULL,
  `frequency`          TINYINT         NOT NULL DEFAULT 1 COMMENT '1=daily | 2=weekly | 3=monthly',
  `send_at`            TIME            DEFAULT NULL,
  `recipients`         JSON            DEFAULT NULL,
  `format`             TINYINT         NOT NULL DEFAULT 1 COMMENT '1=pdf | 2=excel | 3=csv',
  `is_active`          TINYINT(1)      NOT NULL DEFAULT 1,
  `last_sent_at`       TIMESTAMP       NULL DEFAULT NULL,
  `created_by`         CHAR(36)        NOT NULL,
  `created_at`         TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`         TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`         TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sr_tenant_id_idx`         (`tenant_id`),
  KEY `sr_report_template_id_fk` (`report_template_id`),
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
  `metric`     VARCHAR(100)    NOT NULL COMMENT 'total_sales | gross_profit | new_customers | inventory_value',
  `value`      DECIMAL(20,4)   NOT NULL,
  `branch_id`  CHAR(36)        DEFAULT NULL,
  `created_at` TIMESTAMP       NULL DEFAULT NULL,
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
  `module`       VARCHAR(100)    DEFAULT NULL COMMENT 'sales | inventory | hr | finance | crm',
  `description`  VARCHAR(500)    DEFAULT NULL,
  `title`        VARCHAR(255)    NOT NULL,
  `properties`   JSON            DEFAULT NULL COMMENT 'Before/after diff',
  `ip_address`   VARCHAR(45)     DEFAULT NULL,
  `created_at`   TIMESTAMP       NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `al_tenant_id_idx`     (`tenant_id`),
  KEY `al_tenant_module_idx` (`tenant_id`, `module`),
  KEY `al_tenant_subject_idx` (`tenant_id`, `subject_type`, `subject_id`),
  KEY `al_user_id_fk`        (`user_id`),
  CONSTRAINT `al_tenant_id_foreign`
    FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `al_user_id_foreign`
    FOREIGN KEY (`user_id`)   REFERENCES `users`   (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Custom ActivityLog module — audit trail for all model mutations per tenant.';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Laravel in-app notifications (polymorphic). Tenant-neutral — scoped by notifiable_id.';

CREATE TABLE `failed_jobs` (
  `id`         CHAR(36)        NOT NULL,
  `uuid`       VARCHAR(255)    NOT NULL,
  `connection` TEXT            NOT NULL,
  `queue`      TEXT            NOT NULL,
  `payload`    LONGTEXT        NOT NULL,
  `exception`  LONGTEXT        NOT NULL,
  `failed_at`  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `migrations` (
  `id`        INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  `migration` VARCHAR(255)    NOT NULL,
  `batch`     INT             NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Laravel migration tracking table. Uses auto-increment by framework convention.';

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
--  END OF SCHEMA — RAKEEZA ERP v5.0
-- ============================================================