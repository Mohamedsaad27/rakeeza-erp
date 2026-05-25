<?php

namespace App\Modules\Auth\Application\DTOs;

readonly class RegisterDTO
{
    public function __construct(
        public string  $tenantId,
        public string  $name,
        public string  $username,
        public string  $email,
        public string  $password,
        public ?string $phone = null,
    ) {}
}
