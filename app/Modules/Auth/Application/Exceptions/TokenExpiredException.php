<?php

namespace App\Modules\Auth\Application\Exceptions;

use App\Modules\Core\Application\Exceptions\BaseException;

class TokenExpiredException extends BaseException
{
    protected function getDefaultMessage(): string
    {
        return __('auth.token_expired');
    }

    protected function getDefaultStatusCode(): int
    {
        return 401;
    }
}
