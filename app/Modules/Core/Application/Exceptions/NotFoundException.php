<?php

namespace App\Modules\Core\Application\Exceptions;

class NotFoundException extends BaseException
{
    protected function getDefaultMessage(): string
    {
        return __('messages.resource_not_found');
    }

    protected function getDefaultStatusCode(): int
    {
        return 404;
    }
}
