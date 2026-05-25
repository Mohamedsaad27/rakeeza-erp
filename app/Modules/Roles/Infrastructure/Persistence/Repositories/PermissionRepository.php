<?php

namespace App\Modules\Roles\Infrastructure\Persistence\Repositories;

use App\Modules\Roles\Application\DTOs\CreateCustomPermissionDTO;
use App\Modules\Roles\Domain\Interfaces\PermissionRepositoryInterface;
use App\Modules\Roles\Infrastructure\Database\Models\Permission;
use Illuminate\Support\Collection;

class PermissionRepository implements PermissionRepositoryInterface
{
    public function listGrouped(string $tenantId): Collection
    {
        return Permission::query()
            ->accessible($tenantId)
            ->orderBy('module')
            ->orderBy('label_en')
            ->get()
            ->groupBy('module');
    }

    public function findById(string $tenantId, string $permissionId): Permission
    {
        return Permission::query()
            ->accessible($tenantId)
            ->where('permission_id', $permissionId)
            ->firstOrFail();
    }

    public function createCustom(CreateCustomPermissionDTO $dto): Permission
    {
        return Permission::create([
            'tenant_id'      => $dto->tenantId,
            'name'           => $dto->name,
            'guard_name'     => 'api',
            'module'         => $dto->module,
            'label_en'       => $dto->labelEn,
            'label_ar'       => $dto->labelAr,
            'description_en' => $dto->descriptionEn,
            'description_ar' => $dto->descriptionAr,
            'is_system'      => false,
        ]);
    }

    public function deleteCustom(Permission $permission): void
    {
        $permission->delete();
    }

    public function findByIdsForTenant(string $tenantId, array $permissionIds): Collection
    {
        return Permission::query()
            ->accessible($tenantId)
            ->whereIn('permission_id', $permissionIds)
            ->get();
    }
}
