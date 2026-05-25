<?php

namespace App\Modules\Roles\Presentation\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Core\Infrastructure\Helpers\ApiResponse;
use App\Modules\Roles\Application\DTOs\CreateCustomPermissionDTO;
use App\Modules\Roles\Application\UseCases\CreateCustomPermissionUseCase;
use App\Modules\Roles\Application\UseCases\DeleteCustomPermissionUseCase;
use App\Modules\Roles\Application\UseCases\GetPermissionCatalogUseCase;
use App\Modules\Roles\Domain\Interfaces\RoleRepositoryInterface;
use App\Modules\Roles\Presentation\Http\Requests\StoreCustomPermissionRequest;
use App\Modules\Roles\Presentation\Resources\PermissionGroupResource;
use Illuminate\Http\JsonResponse;

class PermissionController extends Controller
{
    public function __construct(
        private readonly GetPermissionCatalogUseCase $getPermissionCatalogUseCase,
        private readonly CreateCustomPermissionUseCase $createCustomPermissionUseCase,
        private readonly DeleteCustomPermissionUseCase $deleteCustomPermissionUseCase,
        private readonly RoleRepositoryInterface $roleRepository,
    ) {}

    public function index(): JsonResponse
    {
        $catalog = $this->getPermissionCatalogUseCase->execute(app('tenant_id'));

        return ApiResponse::success(
            PermissionGroupResource::collection(collect($catalog)),
            __('roles.permissions_retrieved'),
        );
    }

    public function matrix(): JsonResponse
    {
        $tenantId = app('tenant_id');
        $catalog = $this->getPermissionCatalogUseCase->execute($tenantId);
        $roles = $this->roleRepository->paginate($tenantId, 100);

        $rolesWithPermissions = $roles->getCollection()->map(function ($role) use ($tenantId) {
            $full = $this->roleRepository->getWithPermissions($tenantId, $role->role_id);

            return [
                'id'             => $full->role_id,
                'name'           => $full->name,
                'label'          => app()->getLocale() === 'ar' ? $full->name_ar : $full->name_en,
                'permission_ids' => $full->permissions->pluck('permission_id')->all(),
            ];
        });

        return ApiResponse::success([
            'modules' => PermissionGroupResource::collection(collect($catalog)),
            'roles'   => $rolesWithPermissions,
        ], __('roles.permission_matrix_retrieved'));
    }

    public function store(StoreCustomPermissionRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $data = $this->createCustomPermissionUseCase->execute(new CreateCustomPermissionDTO(
            tenantId: app('tenant_id'),
            name: $validated['name'],
            module: $validated['module'],
            labelEn: $validated['label_en'],
            labelAr: $validated['label_ar'],
            descriptionEn: $validated['description_en'] ?? null,
            descriptionAr: $validated['description_ar'] ?? null,
        ));

        return ApiResponse::success($data, __('roles.permission_created'), 201);
    }

    public function destroy(string $id): JsonResponse
    {
        $this->deleteCustomPermissionUseCase->execute(app('tenant_id'), $id);

        return ApiResponse::success(null, __('roles.permission_deleted'));
    }
}
