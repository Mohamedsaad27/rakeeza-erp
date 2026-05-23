<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // roles
        Schema::create('roles', function (Blueprint $table) {
            $table->uuid('role_id')->primary();
            $table->uuid('tenant_id')->index('roles_tenant_id_idx');
            $table->string('name', 150);
            $table->string('guard_name', 50)->default('api');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['tenant_id', 'name', 'guard_name'], 'roles_tenant_name_guard_unique');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // permissions
        Schema::create('permissions', function (Blueprint $table) {
            $table->uuid('permission_id')->primary();
            $table->uuid('tenant_id')->index('permissions_tenant_id_idx');
            $table->string('name', 150);
            $table->string('guard_name', 50)->default('api');
            $table->timestamps();

            $table->unique(['tenant_id', 'name', 'guard_name'], 'permissions_tenant_name_guard_unique');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // role_user pivot
        Schema::create('role_user', function (Blueprint $table) {
            $table->uuid('role_id');
            $table->uuid('user_id');
            $table->uuid('tenant_id')->index('ru_tenant_id_idx');
            $table->timestamp('created_at')->nullable();

            $table->primary(['role_id', 'user_id']);
            $table->foreign('role_id')->references('role_id')->on('roles')->onDelete('cascade');
            $table->foreign('user_id')->references('user_id')->on('users')->onDelete('cascade');
        });

        // permission_role pivot
        Schema::create('permission_role', function (Blueprint $table) {
            $table->uuid('permission_id');
            $table->uuid('role_id');
            $table->timestamp('created_at')->nullable();

            $table->primary(['permission_id', 'role_id']);
            $table->foreign('permission_id')->references('permission_id')->on('permissions')->onDelete('cascade');
            $table->foreign('role_id')->references('role_id')->on('roles')->onDelete('cascade');
        });

        // permission_user pivot (direct permissions)
        Schema::create('permission_user', function (Blueprint $table) {
            $table->uuid('permission_id');
            $table->uuid('user_id');
            $table->uuid('tenant_id')->index('pu_tenant_id_idx');
            $table->timestamp('created_at')->nullable();

            $table->primary(['permission_id', 'user_id']);
            $table->foreign('permission_id')->references('permission_id')->on('permissions')->onDelete('cascade');
            $table->foreign('user_id')->references('user_id')->on('users')->onDelete('cascade');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('permission_user');
        Schema::dropIfExists('permission_role');
        Schema::dropIfExists('role_user');
        Schema::dropIfExists('permissions');
        Schema::dropIfExists('roles');
        Schema::enableForeignKeyConstraints();
    }
};
