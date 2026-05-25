<?php

namespace App\Modules\Roles\Application\DTOs;

readonly class CreateRoleDTO
{
    public function __construct(
        public string  $tenantId,
        public string  $name,
        public string  $nameEn,
        public string  $nameAr,
        public ?string $displayNameEn = null,
        public ?string $displayNameAr = null,
        public ?string $descriptionEn = null,
        public ?string $descriptionAr = null,
    ) {}
}
