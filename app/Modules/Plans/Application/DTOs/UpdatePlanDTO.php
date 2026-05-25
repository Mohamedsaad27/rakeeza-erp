<?php

namespace App\Modules\Plans\Application\DTOs;

readonly class UpdatePlanDTO
{
    public function __construct(
        public ?string $nameEn = null,
        public ?string $nameAr = null,
        public ?float  $price = null,
        public ?int    $billingCycle = null,
        public ?int    $trialDays = null,
        public ?int    $maxUsers = null,
        public ?int    $maxBranches = null,
        public ?bool   $isActive = null,
    ) {}
}
