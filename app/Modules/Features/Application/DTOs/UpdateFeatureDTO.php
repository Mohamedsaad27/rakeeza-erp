<?php

namespace App\Modules\Features\Application\DTOs;

readonly class UpdateFeatureDTO
{
    public function __construct(
        public ?string $nameEn = null,
        public ?string $nameAr = null,
        public ?string $descriptionEn = null,
        public ?string $descriptionAr = null,
        public ?bool   $isActive = null,
    ) {}
}
