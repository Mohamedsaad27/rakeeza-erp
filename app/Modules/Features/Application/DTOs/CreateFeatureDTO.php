<?php

namespace App\Modules\Features\Application\DTOs;

readonly class CreateFeatureDTO
{
    public function __construct(
        public string  $nameEn,
        public string  $nameAr,
        public string  $code,
        public ?string $descriptionEn = null,
        public ?string $descriptionAr = null,
        public bool    $isActive = true,
    ) {}
}
