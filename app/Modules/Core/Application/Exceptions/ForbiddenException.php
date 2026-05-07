<?php

namespace App\Modules\Core\Application\Exceptions;


class ForbiddenException extends BaseException
{
    protected function getDefaultMessage(): string
    {
        return __('messages.insufficient_permissions');
    }

    protected function getDefaultStatusCode(): int
    {
        return 403;
    }
}
