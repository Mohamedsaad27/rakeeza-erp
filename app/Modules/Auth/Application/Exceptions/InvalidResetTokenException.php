<?php

namespace App\Modules\Auth\Application\Exceptions;

use App\Modules\Core\Application\Exceptions\BaseException;

class InvalidResetTokenException extends BaseException
{
    protected function getDefaultMessage(): string
    {
        return __('auth.invalid_reset_token');
    }

    protected function getDefaultStatusCode(): int
    {
        return 400;
    }
}
