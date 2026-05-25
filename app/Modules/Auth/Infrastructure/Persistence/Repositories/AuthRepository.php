<?php

namespace App\Modules\Auth\Infrastructure\Persistence\Repositories;

use App\Modules\Auth\Application\DTOs\RegisterDTO;
use App\Modules\Auth\Domain\Interfaces\AuthRepositoryInterface;
use App\Modules\Auth\Infrastructure\Database\Models\PasswordReset;
use App\Modules\Auth\Infrastructure\Database\Models\User;
use App\Modules\Core\Infrastructure\Scopes\TenantScope;

class AuthRepository implements AuthRepositoryInterface
{
    public function findByLoginForTenant(string $tenantId, string $login): ?User
    {
        return User::withoutGlobalScope(TenantScope::class)
            ->where('tenant_id', $tenantId)
            ->where(function ($query) use ($login) {
                $query->where('email', $login)
                    ->orWhere('username', $login);
            })
            ->first();
    }

    public function findByLoginForPlatform(string $login): ?User
    {
        return User::withoutGlobalScope(TenantScope::class)
            ->whereNull('tenant_id')
            ->where(function ($query) use ($login) {
                $query->where('email', $login)
                    ->orWhere('username', $login);
            })
            ->first();
    }

    public function findByEmailForTenant(string $tenantId, string $email): ?User
    {
        return User::withoutGlobalScope(TenantScope::class)
            ->where('tenant_id', $tenantId)
            ->where('email', $email)
            ->first();
    }

    public function findByEmailForPlatform(string $email): ?User
    {
        return User::withoutGlobalScope(TenantScope::class)
            ->whereNull('tenant_id')
            ->where('email', $email)
            ->first();
    }

    public function createUser(RegisterDTO $dto): User
    {
        return User::withoutGlobalScope(TenantScope::class)->create([
            'tenant_id' => $dto->tenantId,
            'name'      => $dto->name,
            'username'  => $dto->username,
            'email'     => $dto->email,
            'phone'     => $dto->phone,
            'password'  => $dto->password,
            'is_active' => true,
        ]);
    }

    public function updateLastLogin(string $userId): void
    {
        User::withoutGlobalScope(TenantScope::class)
            ->where('user_id', $userId)
            ->update(['last_login_at' => now()]);
    }

    public function updatePassword(string $userId, string $password): void
    {
        $user = User::withoutGlobalScope(TenantScope::class)
            ->where('user_id', $userId)
            ->firstOrFail();

        $user->update(['password' => $password]);
    }

    public function createPasswordReset(?string $tenantId, string $email, string $hashedToken, \DateTimeInterface $expiresAt): PasswordReset
    {
        return PasswordReset::create([
            'tenant_id'  => $tenantId,
            'email'      => $email,
            'token'      => $hashedToken,
            'created_at' => now(),
            'expires_at' => $expiresAt,
        ]);
    }

    public function findPasswordReset(?string $tenantId, string $email): ?PasswordReset
    {
        $query = PasswordReset::where('email', $email);

        if ($tenantId === null) {
            $query->whereNull('tenant_id');
        } else {
            $query->where('tenant_id', $tenantId);
        }

        return $query->latest('created_at')->first();
    }

    public function deletePasswordReset(string $passwordResetId): void
    {
        PasswordReset::where('password_reset_id', $passwordResetId)->delete();
    }

    public function deletePasswordResetsForEmail(?string $tenantId, string $email): void
    {
        $query = PasswordReset::where('email', $email);

        if ($tenantId === null) {
            $query->whereNull('tenant_id');
        } else {
            $query->where('tenant_id', $tenantId);
        }

        $query->delete();
    }
}
