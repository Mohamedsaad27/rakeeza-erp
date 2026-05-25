<?php

namespace App\Modules\Auth\Domain\Interfaces;

use App\Modules\Auth\Application\DTOs\RegisterDTO;
use App\Modules\Auth\Infrastructure\Database\Models\PasswordReset;
use App\Modules\Auth\Infrastructure\Database\Models\User;

interface AuthRepositoryInterface
{
    public function findByLoginForTenant(string $tenantId, string $login): ?User;

    public function findByLoginForPlatform(string $login): ?User;

    public function findByEmailForTenant(string $tenantId, string $email): ?User;

    public function findByEmailForPlatform(string $email): ?User;

    public function createUser(RegisterDTO $dto): User;

    public function updateLastLogin(string $userId): void;

    public function updatePassword(string $userId, string $password): void;

    public function createPasswordReset(?string $tenantId, string $email, string $hashedToken, \DateTimeInterface $expiresAt): PasswordReset;

    public function findPasswordReset(?string $tenantId, string $email): ?PasswordReset;

    public function deletePasswordReset(string $passwordResetId): void;

    public function deletePasswordResetsForEmail(?string $tenantId, string $email): void;
}
