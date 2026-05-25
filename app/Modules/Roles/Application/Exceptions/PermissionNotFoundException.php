<?php

namespace App\Modules\Roles\Application\Exceptions;

use App\Modules\Core\Application\Exceptions\BaseException;

class PermissionNotFoundException extends BaseException
{
    protected function getDefaultMessage(): string
    {
        return __('roles.permission_not_found');
    }

    protected function getDefaultStatusCode(): int
    {
        return 404;
    }
}
