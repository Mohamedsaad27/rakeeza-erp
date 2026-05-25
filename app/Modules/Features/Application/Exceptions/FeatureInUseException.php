<?php

namespace App\Modules\Features\Application\Exceptions;

use App\Modules\Core\Application\Exceptions\BaseException;

class FeatureInUseException extends BaseException
{
    protected function getDefaultMessage(): string
    {
        return __('features.feature_in_use');
    }

    protected function getDefaultStatusCode(): int
    {
        return 409;
    }
}
