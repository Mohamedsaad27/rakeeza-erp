<?php

namespace App\Modules\Auth\Application\DTOs;

readonly class ResetPasswordDTO
{
    public function __construct(
        public string  $token,
        public string  $email,
        public string  $password,
        public ?string $tenantId = null,
    ) {}
}
