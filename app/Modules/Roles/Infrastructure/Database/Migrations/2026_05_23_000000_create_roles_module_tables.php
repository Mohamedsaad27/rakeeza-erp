<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        Schema::create('roles', function (Blueprint $table) {
            $table->uuid('role_id')->primary();
            $table->uuid('tenant_id')->index('roles_tenant_id_idx');
            $table->string('name', 150);
            $table->string('guard_name', 50)->default('api');
            $table->string('name_en', 255);
            $table->string('name_ar', 255);
            $table->string('display_name_en', 255)->nullable();
            $table->string('display_name_ar', 255)->nullable();
            $table->string('description_en', 500)->nullable();
            $table->string('description_ar', 500)->nullable();
            $table->boolean('is_system')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'name', 'guard_name'], 'roles_tenant_name_guard_unique');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        Schema::create('permissions', function (Blueprint $table) {
            $table->uuid('permission_id')->primary();
            $table->uuid('tenant_id')->nullable()->index('permissions_tenant_id_idx');
            $table->string('name', 150);
            $table->string('guard_name', 50)->default('api');
            $table->string('module', 100)->nullable()->index('permissions_module_idx');
            $table->string('label_en', 255);
            $table->string('label_ar', 255);
            $table->string('description_en', 500)->nullable();
            $table->string('description_ar', 500)->nullable();
            $table->boolean('is_system')->default(false);
            $table->timestamps();

            $table->unique(['tenant_id', 'name', 'guard_name'], 'permissions_tenant_name_guard_unique');
        });

        Schema::create('role_has_permissions', function (Blueprint $table) {
            $table->uuid('permission_id');
            $table->uuid('role_id');
            $table->uuid('tenant_id')->index('rhp_tenant_id_idx');

            $table->primary(['permission_id', 'role_id']);
            $table->foreign('permission_id')->references('permission_id')->on('permissions')->onDelete('cascade');
            $table->foreign('role_id')->references('role_id')->on('roles')->onDelete('cascade');
        });

        Schema::create('model_has_roles', function (Blueprint $table) {
            $table->uuid('role_id');
            $table->string('model_type');
            $table->uuid('model_id');
            $table->uuid('tenant_id')->index('mhr_tenant_id_idx');

            $table->primary(['role_id', 'model_id', 'model_type']);
            $table->index(['model_id', 'model_type'], 'mhr_model_id_model_type_index');
            $table->foreign('role_id')->references('role_id')->on('roles')->onDelete('cascade');
        });

        Schema::create('model_has_permissions', function (Blueprint $table) {
            $table->uuid('permission_id');
            $table->string('model_type');
            $table->uuid('model_id');
            $table->uuid('tenant_id')->index('mhp_tenant_id_idx');

            $table->primary(['permission_id', 'model_id', 'model_type']);
            $table->index(['model_id', 'model_type'], 'mhp_model_id_model_type_index');
            $table->foreign('permission_id')->references('permission_id')->on('permissions')->onDelete('cascade');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('model_has_permissions');
        Schema::dropIfExists('model_has_roles');
        Schema::dropIfExists('role_has_permissions');
        Schema::dropIfExists('permissions');
        Schema::dropIfExists('roles');
        Schema::enableForeignKeyConstraints();
    }
};
