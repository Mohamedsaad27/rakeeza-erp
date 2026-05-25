<?php

namespace App\Modules\Plans\Application\Exceptions;

use App\Modules\Core\Application\Exceptions\BaseException;

class PlanInUseException extends BaseException
{
    protected function getDefaultMessage(): string
    {
        return __('plans.plan_in_use');
    }

    protected function getDefaultStatusCode(): int
    {
        return 409;
    }
}
