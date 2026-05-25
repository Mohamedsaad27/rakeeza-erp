<?php

namespace App\Modules\Plans\Application\DTOs;

readonly class SyncPlanLimitsDTO
{
    public function __construct(
        public string $planId,
        /** @var array<string, int> key => value */
        public array  $limits,
    ) {}
}
