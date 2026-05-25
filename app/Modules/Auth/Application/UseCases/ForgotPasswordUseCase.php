<?php

namespace App\Modules\Auth\Application\UseCases;

use App\Modules\Auth\Application\DTOs\ForgotPasswordDTO;
use App\Modules\Auth\Domain\Interfaces\AuthRepositoryInterface;
use App\Modules\Auth\Infrastructure\Notifications\PasswordResetNotification;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class ForgotPasswordUseCase
{
    public function __construct(
        private readonly AuthRepositoryInterface $repository,
    ) {}

    public function execute(ForgotPasswordDTO $dto): void
    {
        $user = $dto->tenantId === null
            ? $this->repository->findByEmailForPlatform($dto->email)
            : $this->repository->findByEmailForTenant($dto->tenantId, $dto->email);

        if (! $user) {
            return;
        }

        $plainToken = Str::random(64);

        $this->repository->deletePasswordResetsForEmail($dto->tenantId, $dto->email);

        $this->repository->createPasswordReset(
            tenantId: $dto->tenantId,
            email: $dto->email,
            hashedToken: Hash::make($plainToken),
            expiresAt: now()->addMinutes(60),
        );

        $user->notify(new PasswordResetNotification($plainToken, $dto->tenantId));
    }
}
