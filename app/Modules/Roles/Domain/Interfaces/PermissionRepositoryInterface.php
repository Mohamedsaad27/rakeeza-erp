<?php

namespace App\Modules\Roles\Domain\Interfaces;

use App\Modules\Roles\Application\DTOs\CreateCustomPermissionDTO;
use App\Modules\Roles\Infrastructure\Database\Models\Permission;
use Illuminate\Support\Collection;

interface PermissionRepositoryInterface
{
    public function listGrouped(string $tenantId): Collection;

    public function findById(string $tenantId, string $permissionId): Permission;

    public function createCustom(CreateCustomPermissionDTO $dto): Permission;

    public function deleteCustom(Permission $permission): void;

    public function findByIdsForTenant(string $tenantId, array $permissionIds): Collection;
}
