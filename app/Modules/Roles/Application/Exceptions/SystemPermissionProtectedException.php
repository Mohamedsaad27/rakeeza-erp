<?php

namespace App\Modules\Roles\Application\Exceptions;

use App\Modules\Core\Application\Exceptions\BaseException;

class SystemPermissionProtectedException extends BaseException
{
    protected function getDefaultMessage(): string
    {
        return __('roles.system_permission_protected');
    }

    protected function getDefaultStatusCode(): int
    {
        return 403;
    }
}
