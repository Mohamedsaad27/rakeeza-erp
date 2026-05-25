<?php

namespace App\Modules\Roles\Domain\Interfaces;

use App\Modules\Roles\Application\DTOs\CreateRoleDTO;
use App\Modules\Roles\Application\DTOs\UpdateRoleDTO;
use App\Modules\Roles\Infrastructure\Database\Models\Role;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

interface RoleRepositoryInterface
{
    public function paginate(string $tenantId, int $perPage = 15): LengthAwarePaginator;

    public function findById(string $tenantId, string $roleId): Role;

    public function create(CreateRoleDTO $dto): Role;

    public function update(Role $role, UpdateRoleDTO $dto): Role;

    public function delete(Role $role): void;

    public function syncPermissions(Role $role, array $permissionIds, string $tenantId): void;

    public function getWithPermissions(string $tenantId, string $roleId): Role;
}
