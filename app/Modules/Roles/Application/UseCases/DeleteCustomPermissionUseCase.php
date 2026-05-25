<?php

namespace App\Modules\Roles\Application\UseCases;

use App\Modules\ActivityLog\Application\DTOs\LogActivityDTO;
use App\Modules\ActivityLog\Application\UseCases\LogActivityUseCase;
use App\Modules\Roles\Application\Exceptions\SystemPermissionProtectedException;
use App\Modules\Roles\Domain\Interfaces\PermissionRepositoryInterface;

class DeleteCustomPermissionUseCase
{
    public function __construct(
        private readonly PermissionRepositoryInterface $repository,
        private readonly LogActivityUseCase $logActivity,
    ) {}

    public function execute(string $tenantId, string $permissionId): void
    {
        $permission = $this->repository->findById($tenantId, $permissionId);

        if ($permission->is_system || $permission->tenant_id === null) {
            throw new SystemPermissionProtectedException();
        }

        $this->repository->deleteCustom($permission);

        $this->logActivity->execute(new LogActivityDTO(
            event: 'permission.deleted',
            entityType: 'permission',
            entityId: $permissionId,
            tenantId: $tenantId,
            userId: auth()->id(),
        ));
    }
}
