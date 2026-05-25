<?php

namespace App\Modules\Auth\Application\Exceptions;

use App\Modules\Core\Application\Exceptions\BaseException;

class InvalidCredentialsException extends BaseException
{
    protected function getDefaultMessage(): string
    {
        return __('auth.invalid_credentials');
    }

    protected function getDefaultStatusCode(): int
    {
        return 401;
    }
}
