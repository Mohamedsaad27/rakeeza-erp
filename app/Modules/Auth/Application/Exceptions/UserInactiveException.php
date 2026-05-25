<?php

namespace App\Modules\Auth\Application\Exceptions;

use App\Modules\Core\Application\Exceptions\BaseException;

class UserInactiveException extends BaseException
{
    protected function getDefaultMessage(): string
    {
        return __('auth.user_inactive');
    }

    protected function getDefaultStatusCode(): int
    {
        return 403;
    }
}
