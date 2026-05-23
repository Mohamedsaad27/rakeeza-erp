<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. expense_categories
        Schema::create('expense_categories', function (Blueprint $table) {
            $table->uuid('expense_category_id')->primary();
            $table->uuid('tenant_id')->index('expense_categories_tenant_id_idx');
            $table->string('name_en');
            $table->string('name_ar');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // 2. expenses
        Schema::create('expenses', function (Blueprint $table) {
            $table->uuid('expense_id')->primary();
            $table->uuid('tenant_id')->index('expenses_tenant_id_idx');
            $table->uuid('expense_category_id')->index('expenses_expense_category_id_fk');
            $table->uuid('account_id')->index('expenses_account_id_fk');
            $table->uuid('branch_id')->index('expenses_branch_id_fk');
            $table->uuid('cost_center_id')->nullable()->index('expenses_cost_center_id_fk');
            $table->decimal('amount', 15, 4);
            $table->date('expense_date');
            $table->string('ref_no', 100)->nullable();
            $table->string('note', 500)->nullable();
            $table->uuid('created_by')->nullable()->index('expenses_created_by_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('expense_category_id')->references('expense_category_id')->on('expense_categories')->onDelete('restrict');
            $table->foreign('account_id')->references('account_id')->on('accounts')->onDelete('restrict');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('restrict');
            $table->foreign('cost_center_id')->references('cost_center_id')->on('cost_centers')->onDelete('set null');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('set null');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('expenses');
        Schema::dropIfExists('expense_categories');
        Schema::enableForeignKeyConstraints();
    }
};
