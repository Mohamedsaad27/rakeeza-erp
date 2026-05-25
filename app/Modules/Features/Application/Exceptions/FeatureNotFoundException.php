<?php

namespace App\Modules\Features\Application\Exceptions;

use App\Modules\Core\Application\Exceptions\BaseException;

class FeatureNotFoundException extends BaseException
{
    protected function getDefaultMessage(): string
    {
        return __('features.feature_not_found');
    }

    protected function getDefaultStatusCode(): int
    {
        return 404;
    }
}
