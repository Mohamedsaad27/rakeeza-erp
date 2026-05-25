<?php

namespace App\Modules\Plans\Application\Exceptions;

use App\Modules\Core\Application\Exceptions\BaseException;

class PlanNotFoundException extends BaseException
{
    protected function getDefaultMessage(): string
    {
        return __('plans.plan_not_found');
    }

    protected function getDefaultStatusCode(): int
    {
        return 404;
    }
}
