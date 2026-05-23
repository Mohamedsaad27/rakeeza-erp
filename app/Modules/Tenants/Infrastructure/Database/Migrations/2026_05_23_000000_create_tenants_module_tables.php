<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. plans
        Schema::create('plans', function (Blueprint $table) {
            $table->uuid('plan_id')->primary();
            $table->string('name_en', 150);
            $table->string('name_ar', 150);
            $table->decimal('price', 15, 4)->default(0.0000);
            $table->tinyInteger('billing_cycle')->default(1)->comment('1=monthly | 2=quarterly | 3=yearly');
            $table->smallInteger('trial_days')->default(0);
            $table->integer('max_users')->nullable()->comment('NULL = unlimited');
            $table->integer('max_branches')->nullable()->comment('NULL = unlimited');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
        });

        // 2. plan_limits
        Schema::create('plan_limits', function (Blueprint $table) {
            $table->uuid('plan_limit_id')->primary();
            $table->uuid('plan_id');
            $table->string('key', 100)->comment('e.g. max_products | max_warehouses');
            $table->integer('value');
            $table->timestamps();

            $table->unique(['plan_id', 'key'], 'uq_plan_limit_key');
            $table->foreign('plan_id')->references('plan_id')->on('plans')->onDelete('cascade');
        });

        // 3. features
        Schema::create('features', function (Blueprint $table) {
            $table->uuid('feature_id')->primary();
            $table->string('name_en', 150);
            $table->string('name_ar', 150);
            $table->string('code', 100)->unique('features_code_unique');
            $table->text('description_en')->nullable();
            $table->text('description_ar')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 4. plan_features
        Schema::create('plan_features', function (Blueprint $table) {
            $table->uuid('plan_feature_id')->primary();
            $table->uuid('plan_id');
            $table->uuid('feature_id');
            $table->boolean('enabled')->default(true);

            $table->unique(['plan_id', 'feature_id'], 'uq_plan_feature');
            $table->foreign('plan_id')->references('plan_id')->on('plans')->onDelete('cascade');
            $table->foreign('feature_id')->references('feature_id')->on('features')->onDelete('cascade');
        });

        // 5. tenants
        Schema::create('tenants', function (Blueprint $table) {
            $table->uuid('tenant_id')->primary();
            $table->string('name_en', 255);
            $table->string('name_ar', 255);
            $table->string('slug', 100)->unique('tenants_slug_unique')->comment('subdomain: slug.rakeeza.com');
            $table->string('email', 255)->unique('tenants_email_unique')->comment('Owner / billing email');
            $table->string('phone', 50)->nullable();
            $table->string('logo', 500)->nullable();
            $table->tinyInteger('status')->default(1)->index('tenants_status_idx')->comment('1=active | 2=suspended | 3=cancelled');
            $table->timestamp('trial_ends_at')->nullable();
            $table->uuid('plan_id')->nullable()->index('tenants_plan_id_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('plan_id')->references('plan_id')->on('plans')->onDelete('set null');
        });

        // 6. domains
        Schema::create('domains', function (Blueprint $table) {
            $table->uuid('domain_id')->primary();
            $table->uuid('tenant_id')->index('domains_tenant_id_fk');
            $table->string('domain', 255)->unique('domains_domain_unique')->comment('e.g. erp.mycorp.com');
            $table->tinyInteger('status')->default(1)->comment('1=active | 2=inactive | 3=pending_verification');
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // 7. subscriptions
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->uuid('subscription_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('plan_id')->index('subscriptions_plan_id_fk');
            $table->decimal('price_at_purchase', 15, 4)->default(0.0000);
            $table->char('currency_at_purchase', 3)->default('EGP');
            $table->tinyInteger('status')->default(1)->comment('1=active | 2=cancelled | 3=expired | 4=past_due');
            $table->timestamp('start_date');
            $table->timestamp('ends_at');
            $table->boolean('auto_renew')->default(true);
            $table->timestamp('canceled_at')->nullable();
            $table->string('cancel_reason', 500)->nullable();
            $table->timestamps();

            $table->index(['tenant_id', 'status'], 'subscriptions_tenant_status_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('plan_id')->references('plan_id')->on('plans');
        });

        // 8. subscription_history
        Schema::create('subscription_history', function (Blueprint $table) {
            $table->uuid('history_id')->primary();
            $table->uuid('subscription_id')->index('sub_hist_subscription_fk');
            $table->uuid('tenant_id')->index('sub_hist_tenant_idx');
            $table->uuid('old_plan_id')->nullable()->index('sub_hist_old_plan_fk');
            $table->uuid('new_plan_id')->nullable()->index('sub_hist_new_plan_fk');
            $table->tinyInteger('change_type')->comment('1=upgrade | 2=downgrade | 3=renew | 4=cancel');
            $table->uuid('changed_by')->nullable()->comment('platform_users.platform_user_id');
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->nullable();

            $table->foreign('subscription_id')->references('subscription_id')->on('subscriptions');
            $table->foreign('old_plan_id')->references('plan_id')->on('plans')->onDelete('set null');
            $table->foreign('new_plan_id')->references('plan_id')->on('plans')->onDelete('set null');
        });

        // 9. invoices
        Schema::create('invoices', function (Blueprint $table) {
            $table->uuid('invoice_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('subscription_id')->nullable()->index('invoices_subscription_id_fk');
            $table->string('invoice_number', 50)->unique('invoices_number_unique');
            $table->decimal('subtotal', 15, 4)->default(0.0000);
            $table->decimal('tax_amount', 15, 4)->default(0.0000);
            $table->decimal('discount_amount', 15, 4)->default(0.0000);
            $table->decimal('total_amount', 15, 4)->default(0.0000);
            $table->decimal('paid_amount', 15, 4)->default(0.0000);
            $table->char('currency', 3)->default('EGP');
            $table->tinyInteger('status')->default(1)->comment('1=draft | 2=unpaid | 3=paid | 4=overdue | 5=cancelled');
            $table->date('due_date')->nullable();
            $table->timestamp('issued_at')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->string('cancellation_reason', 500)->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index(['tenant_id', 'status'], 'invoices_tenant_status_idx');
            $table->index(['tenant_id', 'due_date'], 'invoices_tenant_due_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('subscription_id')->references('subscription_id')->on('subscriptions')->onDelete('set null');
        });

        // 10. payment_methods
        Schema::create('payment_methods', function (Blueprint $table) {
            $table->uuid('payment_method_id')->primary();
            $table->string('code', 50)->unique('payment_methods_code_unique');
            $table->string('name_en', 100);
            $table->string('name_ar', 100);
            $table->boolean('is_active')->default(true);
        });

        // 11. payments (central SaaS billing payments)
        Schema::create('payments', function (Blueprint $table) {
            $table->uuid('payment_id')->primary();
            $table->uuid('tenant_id')->index('payments_tenant_idx');
            $table->uuid('subscription_id')->nullable();
            $table->uuid('invoice_id')->nullable()->index('payments_invoice_id_fk');
            $table->decimal('amount', 15, 4)->default(0.0000);
            $table->char('currency', 3)->default('EGP');
            $table->uuid('payment_method_id')->nullable()->index('payments_payment_method_id_fk');
            $table->tinyInteger('status')->default(1)->comment('1=pending | 2=success | 3=failed');
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();

            $table->foreign('invoice_id')->references('invoice_id')->on('invoices')->onDelete('set null');
            $table->foreign('payment_method_id')->references('payment_method_id')->on('payment_methods');
        });

        // 12. payment_transactions
        Schema::create('payment_transactions', function (Blueprint $table) {
            $table->uuid('transaction_id')->primary();
            $table->uuid('payment_id')->index('pt_central_payment_fk');
            $table->uuid('invoice_id')->nullable()->index('pt_central_invoice_fk');
            $table->uuid('tenant_id');
            $table->decimal('amount', 15, 4)->default(0.0000);
            $table->char('currency', 3)->default('EGP');
            $table->uuid('payment_method_id')->nullable()->index('pt_central_method_fk');
            $table->tinyInteger('status')->default(1)->comment('1=pending | 2=success | 3=failed');
            $table->string('gateway_name', 100)->nullable();
            $table->string('gateway_transaction_id', 255)->nullable();
            $table->json('gateway_response')->nullable();
            $table->binary('ip_address')->nullable();
            $table->timestamp('attempted_at')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('failed_at')->nullable();
            $table->string('failure_reason', 500)->nullable();
            $table->timestamp('created_at')->nullable();

            $table->index(['tenant_id', 'status'], 'pt_central_tenant_status_idx');
            $table->foreign('payment_id')->references('payment_id')->on('payments');
            $table->foreign('invoice_id')->references('invoice_id')->on('invoices')->onDelete('set null');
            $table->foreign('payment_method_id')->references('payment_method_id')->on('payment_methods');
        });

        // 13. refunds
        Schema::create('refunds', function (Blueprint $table) {
            $table->uuid('refund_id')->primary();
            $table->uuid('transaction_id')->index('refunds_transaction_fk');
            $table->uuid('payment_id')->index('refunds_payment_fk');
            $table->uuid('invoice_id')->nullable()->index('refunds_invoice_fk');
            $table->decimal('amount', 15, 4)->default(0.0000);
            $table->tinyInteger('reason')->nullable()->comment('1=duplicate | 2=fraudulent | 3=requested_by_customer | 4=other');
            $table->text('notes')->nullable();
            $table->uuid('refunded_by')->nullable()->comment('platform_users.platform_user_id');
            $table->string('gateway_refund_id', 255)->nullable();
            $table->tinyInteger('status')->default(1)->comment('1=pending | 2=processed | 3=failed');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('processed_at')->nullable();

            $table->foreign('transaction_id')->references('transaction_id')->on('payment_transactions');
            $table->foreign('payment_id')->references('payment_id')->on('payments');
            $table->foreign('invoice_id')->references('invoice_id')->on('invoices')->onDelete('set null');
        });

        // 14. contact_requests
        Schema::create('contact_requests', function (Blueprint $table) {
            $table->uuid('contact_request_id')->primary();
            $table->string('name');
            $table->string('email');
            $table->string('phone', 50)->nullable();
            $table->string('company')->nullable();
            $table->text('message')->nullable();
            $table->boolean('is_handled')->default(false)->index('contact_requests_is_handled_idx');
            $table->uuid('handled_by')->nullable()->comment('platform_users.platform_user_id');
            $table->timestamp('handled_at')->nullable();
            $table->timestamps();
        });

        // 15. demo_requests
        Schema::create('demo_requests', function (Blueprint $table) {
            $table->uuid('demo_request_id')->primary();
            $table->string('name');
            $table->string('email');
            $table->string('phone', 50)->nullable();
            $table->string('company')->nullable();
            $table->string('company_size', 50)->nullable();
            $table->text('notes')->nullable();
            $table->boolean('is_handled')->default(false)->index('demo_requests_is_handled_idx');
            $table->uuid('handled_by')->nullable()->comment('platform_users.platform_user_id');
            $table->timestamp('handled_at')->nullable();
            $table->timestamps();
        });

        // 16. platform_notifications
        Schema::create('platform_notifications', function (Blueprint $table) {
            $table->uuid('platform_notification_id')->primary();
            $table->string('title_en');
            $table->string('title_ar');
            $table->text('body_en');
            $table->text('body_ar');
            $table->tinyInteger('type')->default(1)->index('pn_type_idx')->comment('1=info | 2=warning | 3=critical | 4=maintenance');
            $table->tinyInteger('target')->default(1)->comment('1=all_tenants | 2=specific_tenants | 3=specific_plans');
            $table->timestamp('scheduled_at')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->uuid('created_by')->nullable()->comment('platform_users.platform_user_id');
            $table->timestamps();
        });

        // 17. platform_notification_targets
        Schema::create('platform_notification_targets', function (Blueprint $table) {
            $table->uuid('platform_notification_target_id')->primary();
            $table->uuid('platform_notification_id');
            $table->uuid('tenant_id');
            $table->tinyInteger('status')->default(1)->comment('1=pending | 2=delivered | 3=read');
            $table->timestamp('delivered_at')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamp('created_at')->nullable();

            $table->unique(['platform_notification_id', 'tenant_id'], 'pnt_notification_tenant_unique');
            $table->index(['tenant_id', 'status'], 'pnt_tenant_status_idx');
            $table->foreign('platform_notification_id')->references('platform_notification_id')->on('platform_notifications')->onDelete('cascade');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('platform_notification_targets');
        Schema::dropIfExists('platform_notifications');
        Schema::dropIfExists('demo_requests');
        Schema::dropIfExists('contact_requests');
        Schema::dropIfExists('refunds');
        Schema::dropIfExists('payment_transactions');
        Schema::dropIfExists('payments');
        Schema::dropIfExists('payment_methods');
        Schema::dropIfExists('invoices');
        Schema::dropIfExists('subscription_history');
        Schema::dropIfExists('subscriptions');
        Schema::dropIfExists('domains');
        Schema::dropIfExists('tenants');
        Schema::dropIfExists('plan_features');
        Schema::dropIfExists('features');
        Schema::dropIfExists('plan_limits');
        Schema::dropIfExists('plans');
        Schema::enableForeignKeyConstraints();
    }
};
