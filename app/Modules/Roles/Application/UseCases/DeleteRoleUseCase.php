<?php

namespace App\Modules\Roles\Application\UseCases;

use App\Modules\ActivityLog\Application\DTOs\LogActivityDTO;
use App\Modules\ActivityLog\Application\UseCases\LogActivityUseCase;
use App\Modules\Roles\Application\Exceptions\SystemRoleProtectedException;
use App\Modules\Roles\Domain\Interfaces\RoleRepositoryInterface;

class DeleteRoleUseCase
{
    public function __construct(
        private readonly RoleRepositoryInterface $repository,
        private readonly LogActivityUseCase $logActivity,
    ) {}

    public function execute(string $tenantId, string $roleId): void
    {
        $role = $this->repository->findById($tenantId, $roleId);

        if ($role->is_system) {
            throw new SystemRoleProtectedException();
        }

        $this->repository->delete($role);

        $this->logActivity->execute(new LogActivityDTO(
            event: 'role.deleted',
            entityType: 'role',
            entityId: $roleId,
            tenantId: $tenantId,
            userId: auth()->id(),
        ));
    }
}
