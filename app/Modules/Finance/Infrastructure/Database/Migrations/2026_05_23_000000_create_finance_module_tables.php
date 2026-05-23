<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. account_types
        Schema::create('account_types', function (Blueprint $table) {
            $table->uuid('account_type_id')->primary();
            $table->string('name_en', 100);
            $table->string('name_ar', 100);
            $table->tinyInteger('normal_balance')->comment('1=debit | 2=credit');
            $table->timestamp('created_at')->nullable();
        });

        // 2. accounts
        Schema::create('accounts', function (Blueprint $table) {
            $table->uuid('account_id')->primary();
            $table->uuid('tenant_id')->index('accounts_tenant_id_idx');
            $table->string('name_en');
            $table->string('name_ar');
            $table->string('number', 100)->nullable();
            $table->decimal('balance', 15, 4)->default(0.0000)->comment('Running balance cache');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // 3. chart_of_accounts
        Schema::create('chart_of_accounts', function (Blueprint $table) {
            $table->uuid('chart_of_account_id')->primary();
            $table->uuid('tenant_id')->index('coa_tenant_id_idx');
            $table->uuid('parent_id')->nullable()->index('coa_parent_id_fk');
            $table->uuid('account_type_id')->index('coa_account_type_id_fk');
            $table->string('code', 50);
            $table->string('name_en');
            $table->string('name_ar');
            $table->text('description_en')->nullable();
            $table->text('description_ar')->nullable();
            $table->string('currency', 10)->default('EGP');
            $table->boolean('is_system')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'code'], 'coa_code_tenant_unique');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('parent_id')->references('chart_of_account_id')->on('chart_of_accounts')->onDelete('set null');
            $table->foreign('account_type_id')->references('account_type_id')->on('account_types');
        });

        // 4. journal_entries
        Schema::create('journal_entries', function (Blueprint $table) {
            $table->uuid('journal_entry_id')->primary();
            $table->uuid('tenant_id');
            $table->string('entry_number', 100)->nullable();
            $table->date('entry_date');
            $table->string('reference_type', 100)->nullable()->comment('sales_transaction | purchase_transaction | etc');
            $table->uuid('reference_id')->nullable();
            $table->text('description')->nullable();
            $table->boolean('is_posted')->default(false);
            $table->timestamp('posted_at')->nullable();
            $table->uuid('posted_by')->nullable()->index('je_posted_by_fk');
            $table->uuid('created_by')->index('je_created_by_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'entry_date'], 'je_tenant_date_idx');
            $table->index(['reference_type', 'reference_id'], 'je_reference_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('posted_by')->references('user_id')->on('users')->onDelete('set null');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('cascade');
        });

        // 5. journal_entry_lines
        Schema::create('journal_entry_lines', function (Blueprint $table) {
            $table->uuid('journal_entry_line_id')->primary();
            $table->uuid('journal_entry_id')->index('jel_journal_entry_id_fk');
            $table->uuid('account_id')->index('jel_account_id_fk')->comment('chart_of_account_id');
            $table->decimal('debit', 15, 4)->default(0.0000);
            $table->decimal('credit', 15, 4)->default(0.0000);
            $table->string('description', 500)->nullable();
            $table->softDeletes();

            $table->foreign('journal_entry_id')->references('journal_entry_id')->on('journal_entries')->onDelete('cascade');
            $table->foreign('account_id')->references('chart_of_account_id')->on('chart_of_accounts');
        });

        // 6. taxes
        Schema::create('taxes', function (Blueprint $table) {
            $table->uuid('tax_id')->primary();
            $table->uuid('tenant_id')->index('taxes_tenant_id_idx');
            $table->string('name_en')->comment('e.g. VAT 14%');
            $table->string('name_ar');
            $table->decimal('rate', 5, 2);
            $table->tinyInteger('type')->default(1)->comment('1=percentage | 2=fixed');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // 7. currencies
        Schema::create('currencies', function (Blueprint $table) {
            $table->uuid('currency_id')->primary();
            $table->uuid('tenant_id')->index('currencies_tenant_id_idx');
            $table->char('code', 3)->comment('ISO 4217');
            $table->string('name_en');
            $table->string('name_ar');
            $table->string('symbol', 10);
            $table->decimal('exchange_rate', 15, 6)->default(1.000000);
            $table->boolean('is_base')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['tenant_id', 'code'], 'currencies_tenant_code_unique');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // 8. cost_centers
        Schema::create('cost_centers', function (Blueprint $table) {
            $table->uuid('cost_center_id')->primary();
            $table->uuid('tenant_id')->index('cost_centers_tenant_id_idx');
            $table->uuid('parent_id')->nullable()->index('cost_centers_parent_id_fk');
            $table->string('name_en');
            $table->string('name_ar');
            $table->string('code', 50)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('parent_id')->references('cost_center_id')->on('cost_centers')->onDelete('set null');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('cost_centers');
        Schema::dropIfExists('currencies');
        Schema::dropIfExists('taxes');
        Schema::dropIfExists('journal_entry_lines');
        Schema::dropIfExists('journal_entries');
        Schema::dropIfExists('chart_of_accounts');
        Schema::dropIfExists('accounts');
        Schema::dropIfExists('account_types');
        Schema::enableForeignKeyConstraints();
    }
};
