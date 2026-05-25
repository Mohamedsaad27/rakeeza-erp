<?php

namespace App\Modules\Roles\Application\UseCases;

use App\Modules\Roles\Domain\Interfaces\PermissionRepositoryInterface;
use App\Modules\Roles\Domain\Services\PermissionCatalogService;

class GetPermissionCatalogUseCase
{
    public function __construct(
        private readonly PermissionRepositoryInterface $repository,
        private readonly PermissionCatalogService $catalogService,
    ) {}

    public function execute(string $tenantId): array
    {
        $grouped = $this->repository->listGrouped($tenantId);

        return $grouped->map(function ($permissions, $module) {
            $moduleLabels = $this->catalogService->resolveModuleLabel((string) $module);

            return [
                'module'    => $module,
                'label_en'  => $moduleLabels['label_en'],
                'label_ar'  => $moduleLabels['label_ar'],
                'label'     => $moduleLabels['label'],
                'permissions' => $permissions->map(fn ($p) => [
                    'id'             => $p->permission_id,
                    'key'            => $p->name,
                    'label_en'       => $p->label_en,
                    'label_ar'       => $p->label_ar,
                    'label'          => $this->catalogService->resolveLabel($p),
                    'description_en' => $p->description_en,
                    'description_ar' => $p->description_ar,
                    'is_system'      => $p->is_system,
                    'is_custom'      => $p->isCustom(),
                ])->values()->all(),
            ];
        })->values()->all();
    }
}
