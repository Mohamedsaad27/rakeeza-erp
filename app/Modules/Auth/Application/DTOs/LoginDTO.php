<?php

namespace App\Modules\Auth\Application\DTOs;

readonly class LoginDTO
{
    public function __construct(
        public string  $login,
        public string  $password,
        public string  $guard,
        public ?string $tenantId = null,
    ) {}
}
