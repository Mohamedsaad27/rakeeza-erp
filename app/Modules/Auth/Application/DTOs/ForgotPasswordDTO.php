<?php

namespace App\Modules\Auth\Application\DTOs;

readonly class ForgotPasswordDTO
{
    public function __construct(
        public string  $email,
        public ?string $tenantId = null,
    ) {}
}
