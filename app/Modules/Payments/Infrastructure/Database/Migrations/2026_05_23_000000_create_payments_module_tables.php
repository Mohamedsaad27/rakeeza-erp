<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. tenant_payments
        Schema::create('tenant_payments', function (Blueprint $table) {
            $table->uuid('tenant_payment_id')->primary();
            $table->uuid('tenant_id')->index('tp_tenant_id_idx');
            $table->uuid('contact_id')->nullable()->index('tp_contact_id_fk');
            $table->uuid('account_id')->nullable()->index('tp_account_id_fk');
            $table->decimal('amount', 15, 4)->default(0.0000);
            $table->string('method', 50)->default('cash')->comment('cash | bank_transfer | check | card');
            $table->tinyInteger('operation')->default(1)->comment('1=add | 2=subtract');
            $table->string('type', 100)->nullable()->comment('payment classification label');
            $table->string('for', 255)->nullable()->comment('free-text description');
            $table->uuid('created_by')->nullable()->index('tp_created_by_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('contact_id')->references('contact_id')->on('contacts')->onDelete('set null');
            $table->foreign('account_id')->references('account_id')->on('accounts')->onDelete('set null');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('set null');
        });

        // 2. tenant_payment_transactions
        Schema::create('tenant_payment_transactions', function (Blueprint $table) {
            $table->uuid('tenant_payment_transaction_id')->primary();
            $table->uuid('tenant_id')->index('tpt_tenant_id_idx');
            $table->tinyInteger('transaction_type')->comment('1=sales | 2=purchase');
            $table->uuid('transaction_id')->comment('Polymorphic -> sales_transactions or purchase_transactions');
            $table->uuid('payment_id')->nullable()->index('tpt_payment_id_fk')->comment('Links to tenant_payments if settling open payment');
            $table->uuid('contact_id')->nullable()->index('tpt_contact_id_fk');
            $table->uuid('account_id')->nullable()->index('tpt_account_id_fk');
            $table->decimal('amount', 15, 4)->default(0.0000);
            $table->string('method', 50)->default('cash');
            $table->tinyInteger('operation')->default(1)->comment('1=add | 2=subtract');
            $table->uuid('created_by')->nullable()->index('tpt_created_by_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['transaction_type', 'transaction_id'], 'tpt_transaction_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('payment_id')->references('tenant_payment_id')->on('tenant_payments')->onDelete('set null');
            $table->foreign('contact_id')->references('contact_id')->on('contacts')->onDelete('set null');
            $table->foreign('account_id')->references('account_id')->on('accounts')->onDelete('set null');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('set null');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('tenant_payment_transactions');
        Schema::dropIfExists('tenant_payments');
        Schema::enableForeignKeyConstraints();
    }
};
