<?php

namespace App\Modules\Roles\Application\DTOs;

readonly class CreateCustomPermissionDTO
{
    public function __construct(
        public string  $tenantId,
        public string  $name,
        public string  $module,
        public string  $labelEn,
        public string  $labelAr,
        public ?string $descriptionEn = null,
        public ?string $descriptionAr = null,
    ) {}
}
