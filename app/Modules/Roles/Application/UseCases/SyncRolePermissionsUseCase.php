<?php

namespace App\Modules\Roles\Application\UseCases;

use App\Modules\ActivityLog\Application\DTOs\LogActivityDTO;
use App\Modules\ActivityLog\Application\UseCases\LogActivityUseCase;
use App\Modules\Roles\Application\DTOs\SyncRolePermissionsDTO;
use App\Modules\Roles\Application\Exceptions\PermissionNotFoundException;
use App\Modules\Roles\Domain\Interfaces\PermissionRepositoryInterface;
use App\Modules\Roles\Domain\Interfaces\RoleRepositoryInterface;

class SyncRolePermissionsUseCase
{
    public function __construct(
        private readonly RoleRepositoryInterface $roleRepository,
        private readonly PermissionRepositoryInterface $permissionRepository,
        private readonly LogActivityUseCase $logActivity,
    ) {}

    public function execute(SyncRolePermissionsDTO $dto): array
    {
        $role = $this->roleRepository->findById($dto->tenantId, $dto->roleId);

        $permissions = $this->permissionRepository->findByIdsForTenant(
            $dto->tenantId,
            $dto->permissionIds,
        );

        if ($permissions->count() !== count(array_unique($dto->permissionIds))) {
            throw new PermissionNotFoundException();
        }

        $this->roleRepository->syncPermissions(
            $role,
            $permissions->pluck('permission_id')->all(),
            $dto->tenantId,
        );

        $this->logActivity->execute(new LogActivityDTO(
            event: 'role.permissions_synced',
            entityType: 'role',
            entityId: $role->role_id,
            tenantId: $dto->tenantId,
            userId: auth()->id(),
            payload: ['permission_ids' => $dto->permissionIds],
        ));

        return ['permission_count' => $permissions->count()];
    }
}
