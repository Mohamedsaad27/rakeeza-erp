<?php

namespace App\Modules\Auth\Application\UseCases;

use App\Modules\Auth\Application\DTOs\ResetPasswordDTO;
use App\Modules\Auth\Application\Exceptions\InvalidResetTokenException;
use App\Modules\Auth\Domain\Interfaces\AuthRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class ResetPasswordUseCase
{
    public function __construct(
        private readonly AuthRepositoryInterface $repository,
    ) {}

    public function execute(ResetPasswordDTO $dto): void
    {
        $resetRecord = $this->repository->findPasswordReset($dto->tenantId, $dto->email);

        if (! $resetRecord || ! Hash::check($dto->token, $resetRecord->token)) {
            throw new InvalidResetTokenException();
        }

        if ($resetRecord->expires_at && $resetRecord->expires_at->isPast()) {
            throw new InvalidResetTokenException(__('auth.reset_token_expired'));
        }

        $user = $dto->tenantId === null
            ? $this->repository->findByEmailForPlatform($dto->email)
            : $this->repository->findByEmailForTenant($dto->tenantId, $dto->email);

        if (! $user) {
            throw new InvalidResetTokenException();
        }

        DB::transaction(function () use ($dto, $user, $resetRecord) {
            $this->repository->updatePassword($user->user_id, $dto->password);
            $this->repository->deletePasswordReset($resetRecord->password_reset_id);
        });
    }
}
