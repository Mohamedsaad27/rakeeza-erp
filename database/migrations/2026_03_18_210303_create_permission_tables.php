<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Rakeeza ERP — Spatie Permission Tables (Tenant-Scoped, UUID Edition)
 */
return new class extends Migration {
    public function up(): void
    {
        $tableNames = config('permission.table_names');
        $columnNames = config('permission.column_names');
        $pivotRole = $columnNames['role_pivot_key'] ?? 'role_id';
        $pivotPermission = $columnNames['permission_pivot_key'] ?? 'permission_id';
        $modelMorphKey = $columnNames['model_morph_key'] ?? 'model_id';

        throw_if(
            empty($tableNames),
            'Error: config/permission.php not loaded. Run [php artisan config:clear] and try again.'
        );

        // ------------------------------------------------------------------ //
        //  permissions
        // ------------------------------------------------------------------ //
        Schema::create($tableNames['permissions'], static function (Blueprint $table) use ($modelMorphKey) {
            $table->uuid('id')->primary();  // CHAR(36) UUID
            $table->uuid('tenant_id')->index();  // tenant scope

            $table->string('name');  // e.g. contact.create
            $table->string('guard_name');  // api | platform

            $table->timestamps();

            // A permission name must be unique per tenant + guard
            $table->unique(['tenant_id', 'name', 'guard_name'], 'permissions_tenant_name_guard_unique');
        });

        // ------------------------------------------------------------------ //
        //  roles
        // ------------------------------------------------------------------ //
        Schema::create($tableNames['roles'], static function (Blueprint $table) {
            $table->uuid('id')->primary();  // CHAR(36) UUID
            $table->uuid('tenant_id')->index();  // tenant scope

            $table->string('name');  // e.g. admin, cashier
            $table->string('guard_name');  // api | platform

            $table->timestamps();

            // A role name must be unique per tenant + guard
            $table->unique(['tenant_id', 'name', 'guard_name'], 'roles_tenant_name_guard_unique');
        });

        // ------------------------------------------------------------------ //
        //  model_has_permissions  (direct permission → user assignments)
        // ------------------------------------------------------------------ //
        Schema::create($tableNames['model_has_permissions'], static function (Blueprint $table) use (
            $tableNames, $pivotPermission, $modelMorphKey
        ) {
            $table->uuid('tenant_id');  // tenant scope (leading index col)
            $table->uuid($pivotPermission);  // FK → permissions.id
            $table->string('model_type');  // e.g. App\Modules\Users\...Models\User
            $table->uuid($modelMorphKey);  // FK → users.user_id (UUID)

            $table
                ->foreign($pivotPermission)
                ->references('id')
                ->on($tableNames['permissions'])
                ->cascadeOnDelete();

            // Composite PK prevents duplicate assignments
            $table->primary(
                ['tenant_id', $pivotPermission, $modelMorphKey, 'model_type'],
                'model_has_permissions_primary'
            );

            // Index for "what permissions does this model have?"
            $table->index(['tenant_id', $modelMorphKey, 'model_type'], 'mhp_tenant_model_index');
        });

        // ------------------------------------------------------------------ //
        //  model_has_roles  (role → user assignments)
        // ------------------------------------------------------------------ //
        Schema::create($tableNames['model_has_roles'], static function (Blueprint $table) use (
            $tableNames, $pivotRole, $modelMorphKey
        ) {
            $table->uuid('tenant_id');  // tenant scope (leading index col)
            $table->uuid($pivotRole);  // FK → roles.id
            $table->string('model_type');  // e.g. App\Modules\Users\...Models\User
            $table->uuid($modelMorphKey);  // FK → users.user_id (UUID)

            $table
                ->foreign($pivotRole)
                ->references('id')
                ->on($tableNames['roles'])
                ->cascadeOnDelete();

            // Composite PK prevents duplicate assignments
            $table->primary(
                ['tenant_id', $pivotRole, $modelMorphKey, 'model_type'],
                'model_has_roles_primary'
            );

            // Index for "what roles does this model have?"
            $table->index(['tenant_id', $modelMorphKey, 'model_type'], 'mhr_tenant_model_index');
        });

        // ------------------------------------------------------------------ //
        //  role_has_permissions  (permission → role assignments)
        // ------------------------------------------------------------------ //
        Schema::create($tableNames['role_has_permissions'], static function (Blueprint $table) use (
            $tableNames, $pivotRole, $pivotPermission
        ) {
            $table->uuid('tenant_id');  // tenant scope (leading index col)
            $table->uuid($pivotPermission);  // FK → permissions.id
            $table->uuid($pivotRole);  // FK → roles.id

            $table
                ->foreign($pivotPermission)
                ->references('id')
                ->on($tableNames['permissions'])
                ->cascadeOnDelete();

            $table
                ->foreign($pivotRole)
                ->references('id')
                ->on($tableNames['roles'])
                ->cascadeOnDelete();

            $table->primary(
                ['tenant_id', $pivotPermission, $pivotRole],
                'role_has_permissions_primary'
            );
        });

        // Flush the Spatie permission cache
        app('cache')
            ->store(config('permission.cache.store') !== 'default' ? config('permission.cache.store') : null)
            ->forget(config('permission.cache.key'));
    }

    public function down(): void
    {
        $tableNames = config('permission.table_names');

        throw_if(
            empty($tableNames),
            'Error: config/permission.php not found. Please publish the package configuration before proceeding, or drop the tables manually.'
        );

        Schema::dropIfExists($tableNames['role_has_permissions']);
        Schema::dropIfExists($tableNames['model_has_roles']);
        Schema::dropIfExists($tableNames['model_has_permissions']);
        Schema::dropIfExists($tableNames['roles']);
        Schema::dropIfExists($tableNames['permissions']);
    }
};
