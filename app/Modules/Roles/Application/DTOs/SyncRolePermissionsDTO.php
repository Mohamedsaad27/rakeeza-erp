<?php

namespace App\Modules\Roles\Application\DTOs;

readonly class SyncRolePermissionsDTO
{
    public function __construct(
        public string $tenantId,
        public string $roleId,
        public array  $permissionIds,
    ) {}
}
