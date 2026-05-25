<?php

namespace App\Modules\Roles\Application\UseCases;

use App\Modules\ActivityLog\Application\DTOs\LogActivityDTO;
use App\Modules\ActivityLog\Application\UseCases\LogActivityUseCase;
use App\Modules\Roles\Application\DTOs\UpdateRoleDTO;
use App\Modules\Roles\Domain\Interfaces\RoleRepositoryInterface;

class UpdateRoleUseCase
{
    public function __construct(
        private readonly RoleRepositoryInterface $repository,
        private readonly LogActivityUseCase $logActivity,
    ) {}

    public function execute(string $tenantId, string $roleId, UpdateRoleDTO $dto): array
    {
        $role = $this->repository->findById($tenantId, $roleId);
        $role = $this->repository->update($role, $dto);

        $this->logActivity->execute(new LogActivityDTO(
            event: 'role.updated',
            entityType: 'role',
            entityId: $role->role_id,
            tenantId: $tenantId,
            userId: auth()->id(),
        ));

        return [
            'id'              => $role->role_id,
            'name'            => $role->name,
            'name_en'         => $role->name_en,
            'name_ar'         => $role->name_ar,
            'display_name_en' => $role->display_name_en,
            'display_name_ar' => $role->display_name_ar,
            'description_en'  => $role->description_en,
            'description_ar'  => $role->description_ar,
            'is_system'       => $role->is_system,
            'is_active'       => $role->is_active,
        ];
    }
}
