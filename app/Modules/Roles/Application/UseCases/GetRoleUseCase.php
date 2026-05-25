<?php

namespace App\Modules\Roles\Application\UseCases;

use App\Modules\Roles\Domain\Interfaces\RoleRepositoryInterface;
use App\Modules\Roles\Domain\Services\PermissionCatalogService;

class GetRoleUseCase
{
    public function __construct(
        private readonly RoleRepositoryInterface $repository,
        private readonly PermissionCatalogService $catalogService,
    ) {}

    public function execute(string $tenantId, string $roleId): array
    {
        $role = $this->repository->getWithPermissions($tenantId, $roleId);
        $locale = app()->getLocale();

        return [
            'id'              => $role->role_id,
            'name'            => $role->name,
            'name_en'         => $role->name_en,
            'name_ar'         => $role->name_ar,
            'label'           => $locale === 'ar' ? $role->name_ar : $role->name_en,
            'display_name_en' => $role->display_name_en,
            'display_name_ar' => $role->display_name_ar,
            'description_en'  => $role->description_en,
            'description_ar'  => $role->description_ar,
            'is_system'       => $role->is_system,
            'is_active'       => $role->is_active,
            'permissions'     => $role->permissions->map(fn ($p) => [
                'id'            => $p->permission_id,
                'key'           => $p->name,
                'label_en'      => $p->label_en,
                'label_ar'      => $p->label_ar,
                'label'         => $this->catalogService->resolveLabel($p),
                'module'        => $p->module,
                'is_system'     => $p->is_system,
                'is_custom'     => $p->isCustom(),
            ])->values()->all(),
        ];
    }
}
