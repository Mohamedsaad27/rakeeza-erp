<?php

namespace App\Modules\Roles\Presentation\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Core\Infrastructure\Helpers\ApiResponse;
use App\Modules\Core\Infrastructure\Helpers\PaginationMeta;
use App\Modules\Roles\Application\DTOs\CreateRoleDTO;
use App\Modules\Roles\Application\DTOs\SyncRolePermissionsDTO;
use App\Modules\Roles\Application\DTOs\UpdateRoleDTO;
use App\Modules\Roles\Application\UseCases\CreateRoleUseCase;
use App\Modules\Roles\Application\UseCases\DeleteRoleUseCase;
use App\Modules\Roles\Application\UseCases\GetRoleUseCase;
use App\Modules\Roles\Application\UseCases\GetRolesUseCase;
use App\Modules\Roles\Application\UseCases\SyncRolePermissionsUseCase;
use App\Modules\Roles\Application\UseCases\UpdateRoleUseCase;
use App\Modules\Roles\Presentation\Http\Requests\StoreRoleRequest;
use App\Modules\Roles\Presentation\Http\Requests\SyncRolePermissionsRequest;
use App\Modules\Roles\Presentation\Http\Requests\UpdateRoleRequest;
use App\Modules\Roles\Presentation\Resources\RoleResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RoleController extends Controller
{
    public function __construct(
        private readonly GetRolesUseCase $getRolesUseCase,
        private readonly GetRoleUseCase $getRoleUseCase,
        private readonly CreateRoleUseCase $createRoleUseCase,
        private readonly UpdateRoleUseCase $updateRoleUseCase,
        private readonly DeleteRoleUseCase $deleteRoleUseCase,
        private readonly SyncRolePermissionsUseCase $syncRolePermissionsUseCase,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $roles = $this->getRolesUseCase->execute(
            app('tenant_id'),
            (int) $request->input('per_page', 15),
        );

        return response()->json([
            'isSuccess' => true,
            'message'   => __('messages.success'),
            'data'      => RoleResource::collection($roles->items()),
            'meta'      => PaginationMeta::getMeta($roles),
        ]);
    }

    public function store(StoreRoleRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $data = $this->createRoleUseCase->execute(new CreateRoleDTO(
            tenantId: app('tenant_id'),
            name: $validated['name'],
            nameEn: $validated['name_en'],
            nameAr: $validated['name_ar'],
            displayNameEn: $validated['display_name_en'] ?? null,
            displayNameAr: $validated['display_name_ar'] ?? null,
            descriptionEn: $validated['description_en'] ?? null,
            descriptionAr: $validated['description_ar'] ?? null,
        ));

        return ApiResponse::success($data, __('roles.role_created'), 201);
    }

    public function show(string $id): JsonResponse
    {
        $data = $this->getRoleUseCase->execute(app('tenant_id'), $id);

        return ApiResponse::success($data, __('roles.role_retrieved'));
    }

    public function update(UpdateRoleRequest $request, string $id): JsonResponse
    {
        $validated = $request->validated();

        $data = $this->updateRoleUseCase->execute(
            app('tenant_id'),
            $id,
            new UpdateRoleDTO(
                nameEn: $validated['name_en'] ?? null,
                nameAr: $validated['name_ar'] ?? null,
                displayNameEn: $validated['display_name_en'] ?? null,
                displayNameAr: $validated['display_name_ar'] ?? null,
                descriptionEn: $validated['description_en'] ?? null,
                descriptionAr: $validated['description_ar'] ?? null,
                isActive: $validated['is_active'] ?? null,
            ),
        );

        return ApiResponse::success($data, __('roles.role_updated'));
    }

    public function destroy(string $id): JsonResponse
    {
        $this->deleteRoleUseCase->execute(app('tenant_id'), $id);

        return ApiResponse::success(null, __('roles.role_deleted'));
    }

    public function syncPermissions(SyncRolePermissionsRequest $request, string $id): JsonResponse
    {
        $data = $this->syncRolePermissionsUseCase->execute(new SyncRolePermissionsDTO(
            tenantId: app('tenant_id'),
            roleId: $id,
            permissionIds: $request->validated('permission_ids'),
        ));

        return ApiResponse::success($data, __('roles.permissions_synced'));
    }
}
