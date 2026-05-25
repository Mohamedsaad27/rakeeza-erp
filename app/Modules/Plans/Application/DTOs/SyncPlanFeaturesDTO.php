<?php

namespace App\Modules\Plans\Application\DTOs;

readonly class SyncPlanFeaturesDTO
{
    public function __construct(
        public string $planId,
        /** @var array<string, bool> feature_id => enabled */
        public array  $features,
    ) {}
}
