<?php

namespace App\Modules\Roles\Application\DTOs;

readonly class UpdateRoleDTO
{
    public function __construct(
        public ?string $nameEn = null,
        public ?string $nameAr = null,
        public ?string $displayNameEn = null,
        public ?string $displayNameAr = null,
        public ?string $descriptionEn = null,
        public ?string $descriptionAr = null,
        public ?bool   $isActive = null,
    ) {}
}
