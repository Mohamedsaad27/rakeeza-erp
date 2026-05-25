<?php

namespace App\Modules\Roles\Application\UseCases;

use App\Modules\ActivityLog\Application\DTOs\LogActivityDTO;
use App\Modules\ActivityLog\Application\UseCases\LogActivityUseCase;
use App\Modules\Roles\Application\DTOs\CreateCustomPermissionDTO;
use App\Modules\Roles\Domain\Interfaces\PermissionRepositoryInterface;
use App\Modules\Roles\Domain\Services\PermissionCatalogService;

class CreateCustomPermissionUseCase
{
    public function __construct(
        private readonly PermissionRepositoryInterface $repository,
        private readonly PermissionCatalogService $catalogService,
        private readonly LogActivityUseCase $logActivity,
    ) {}

    public function execute(CreateCustomPermissionDTO $dto): array
    {
        $permission = $this->repository->createCustom($dto);

        $this->logActivity->execute(new LogActivityDTO(
            event: 'permission.created',
            entityType: 'permission',
            entityId: $permission->permission_id,
            tenantId: $dto->tenantId,
            userId: auth()->id(),
            payload: ['name' => $permission->name, 'label_en' => $permission->label_en],
        ));

        return [
            'id'             => $permission->permission_id,
            'key'            => $permission->name,
            'label_en'       => $permission->label_en,
            'label_ar'       => $permission->label_ar,
            'label'          => $this->catalogService->resolveLabel($permission),
            'module'         => $permission->module,
            'description_en' => $permission->description_en,
            'description_ar' => $permission->description_ar,
            'is_system'      => false,
            'is_custom'      => true,
        ];
    }
}
