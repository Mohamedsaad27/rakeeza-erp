<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. branches
        Schema::create('branches', function (Blueprint $table) {
            $table->uuid('branch_id')->primary();
            $table->uuid('tenant_id')->index('branches_tenant_id_idx');
            $table->string('name_en', 255);
            $table->string('name_ar', 255);
            $table->string('code', 50)->nullable();
            $table->text('address')->nullable();
            $table->string('phone', 50)->nullable();
            $table->boolean('is_main')->default(false);
            $table->boolean('is_active')->default(true);
            $table->uuid('governorate_id')->nullable()->index('branches_governorate_id_fk');
            $table->uuid('city_id')->nullable()->index('branches_city_id_fk');
            $table->uuid('cash_account_id')->nullable()->index('branches_cash_account_fk')->comment('Deferred FK -> accounts');
            $table->uuid('credit_account_id')->nullable()->index('branches_credit_account_fk')->comment('Deferred FK -> accounts');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('governorate_id')->references('governorate_id')->on('governorates')->onDelete('set null');
            $table->foreign('city_id')->references('city_id')->on('cities')->onDelete('set null');
        });

        // 2. users
        Schema::create('users', function (Blueprint $table) {
            $table->uuid('user_id')->primary();
            $table->uuid('tenant_id')->index('users_tenant_id_idx');
            $table->uuid('branch_id')->nullable()->index('users_branch_id_fk')->comment('Default/home branch');
            $table->string('name', 255);
            $table->string('username', 255);
            $table->string('email', 255)->nullable();
            $table->string('phone', 50)->nullable();
            $table->string('avatar', 500)->nullable();
            $table->string('password', 255);
            $table->string('fcm_token', 500)->nullable()->comment('Firebase Cloud Messaging token for push notifications');
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_login_at')->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'username'], 'users_tenant_username_unique');
            $table->unique(['tenant_id', 'email'], 'users_tenant_email_unique');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('set null');
        });

        // 3. password_resets
        Schema::create('password_resets', function (Blueprint $table) {
            $table->uuid('password_reset_id')->primary();
            $table->uuid('tenant_id')->nullable()->index('password_resets_tenant_id_idx')->comment('Nullable to support platform_users resets too');
            $table->string('email')->index('password_resets_email_idx');
            $table->string('token');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('expires_at')->nullable();

            $table->index(['tenant_id', 'email'], 'password_resets_tenant_email_idx');
        });

        // 4. user_branches
        Schema::create('user_branches', function (Blueprint $table) {
            $table->uuid('user_id');
            $table->uuid('branch_id');
            $table->timestamp('created_at')->nullable();

            $table->primary(['user_id', 'branch_id']);
            $table->index('branch_id', 'user_branches_branch_id_fk');
            $table->foreign('user_id')->references('user_id')->on('users')->onDelete('cascade');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('cascade');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('user_branches');
        Schema::dropIfExists('password_resets');
        Schema::dropIfExists('users');
        Schema::dropIfExists('branches');
        Schema::enableForeignKeyConstraints();
    }
};
