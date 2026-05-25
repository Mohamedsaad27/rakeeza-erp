<?php

namespace App\Modules\Auth\Application\UseCases;

use App\Modules\ActivityLog\Application\DTOs\LogActivityDTO;
use App\Modules\ActivityLog\Application\UseCases\LogActivityUseCase;
use App\Modules\Auth\Application\DTOs\LoginDTO;
use App\Modules\Auth\Application\Exceptions\InvalidCredentialsException;
use App\Modules\Auth\Application\Exceptions\UserInactiveException;
use App\Modules\Auth\Domain\Interfaces\AuthRepositoryInterface;
use Illuminate\Support\Facades\Hash;

class LoginUseCase
{
    public function __construct(
        private readonly AuthRepositoryInterface $repository,
        private readonly LogActivityUseCase $logActivity,
    ) {}

    public function execute(LoginDTO $dto): array
    {
        $user = $dto->guard === 'platform'
            ? $this->repository->findByLoginForPlatform($dto->login)
            : $this->repository->findByLoginForTenant($dto->tenantId, $dto->login);

        if (! $user || ! Hash::check($dto->password, $user->password)) {
            throw new InvalidCredentialsException();
        }

        if (! $user->is_active) {
            throw new UserInactiveException();
        }

        $token = auth($dto->guard)->login($user);

        $this->repository->updateLastLogin($user->user_id);

        if ($user->tenant_id) {
            $this->logActivity->execute(new LogActivityDTO(
                event: 'auth.login',
                entityType: 'user',
                entityId: $user->user_id,
                tenantId: $user->tenant_id,
                userId: $user->user_id,
            ));
        }

        return $this->buildAuthResponse($user, $token, $dto->guard);
    }

    protected function buildAuthResponse(object $user, string $token, string $guard): array
    {
        return [
            'user' => [
                'id'            => $user->user_id,
                'name'          => $user->name,
                'username'      => $user->username,
                'email'         => $user->email,
                'phone'         => $user->phone,
                'avatar'        => $user->avatar,
                'is_active'     => $user->is_active,
                'last_login_at' => $user->last_login_at?->toIso8601String(),
            ],
            'token'      => $token,
            'token_type' => 'bearer',
            'expires_in' => auth($guard)->factory()->getTTL() * 60,
        ];
    }
}
