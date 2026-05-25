<?php

namespace App\Modules\Plans\Application\DTOs;

readonly class CreatePlanDTO
{
    public function __construct(
        public string  $nameEn,
        public string  $nameAr,
        public float   $price,
        public int     $billingCycle,
        public int     $trialDays = 0,
        public ?int    $maxUsers = null,
        public ?int    $maxBranches = null,
        public bool    $isActive = true,
    ) {}
}
