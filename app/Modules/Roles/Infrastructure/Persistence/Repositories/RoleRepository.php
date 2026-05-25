<?php

namespace App\Modules\Roles\Infrastructure\Persistence\Repositories;

use App\Modules\Core\Infrastructure\Scopes\TenantScope;
use App\Modules\Roles\Application\DTOs\CreateRoleDTO;
use App\Modules\Roles\Application\DTOs\UpdateRoleDTO;
use App\Modules\Roles\Domain\Interfaces\RoleRepositoryInterface;
use App\Modules\Roles\Infrastructure\Database\Models\Role;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class RoleRepository implements RoleRepositoryInterface
{
    public function paginate(string $tenantId, int $perPage = 15): LengthAwarePaginator
    {
        return Role::withoutGlobalScope(TenantScope::class)
            ->where('tenant_id', $tenantId)
            ->withCount('permissions')
            ->orderBy('name_en')
            ->paginate($perPage);
    }

    public function findById(string $tenantId, string $roleId): Role
    {
        return Role::withoutGlobalScope(TenantScope::class)
            ->where('tenant_id', $tenantId)
            ->where('role_id', $roleId)
            ->firstOrFail();
    }

    public function create(CreateRoleDTO $dto): Role
    {
        return Role::withoutGlobalScope(TenantScope::class)->create([
            'tenant_id'        => $dto->tenantId,
            'name'             => $dto->name,
            'guard_name'       => 'api',
            'name_en'          => $dto->nameEn,
            'name_ar'          => $dto->nameAr,
            'display_name_en'  => $dto->displayNameEn,
            'display_name_ar'  => $dto->displayNameAr,
            'description_en'   => $dto->descriptionEn,
            'description_ar'   => $dto->descriptionAr,
            'is_system'        => false,
            'is_active'        => true,
        ]);
    }

    public function update(Role $role, UpdateRoleDTO $dto): Role
    {
        $role->update(array_filter([
            'name_en'         => $dto->nameEn,
            'name_ar'         => $dto->nameAr,
            'display_name_en' => $dto->displayNameEn,
            'display_name_ar' => $dto->displayNameAr,
            'description_en'  => $dto->descriptionEn,
            'description_ar'  => $dto->descriptionAr,
            'is_active'       => $dto->isActive,
        ], fn ($value) => $value !== null));

        return $role->fresh(['permissions']);
    }

    public function delete(Role $role): void
    {
        $role->delete();
    }

    public function syncPermissions(Role $role, array $permissionIds, string $tenantId): void
    {
        $role->syncPermissions($permissionIds);

        DB::table('role_has_permissions')
            ->where('role_id', $role->role_id)
            ->update(['tenant_id' => $tenantId]);
    }

    public function getWithPermissions(string $tenantId, string $roleId): Role
    {
        return Role::withoutGlobalScope(TenantScope::class)
            ->where('tenant_id', $tenantId)
            ->where('role_id', $roleId)
            ->with('permissions')
            ->firstOrFail();
    }
}
