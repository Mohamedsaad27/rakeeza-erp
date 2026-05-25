<?php

namespace App\Modules\Auth\Application\UseCases;

use App\Modules\ActivityLog\Application\DTOs\LogActivityDTO;
use App\Modules\ActivityLog\Application\UseCases\LogActivityUseCase;
use App\Modules\Auth\Application\DTOs\RegisterDTO;
use App\Modules\Auth\Domain\Interfaces\AuthRepositoryInterface;
use Illuminate\Support\Facades\DB;

class RegisterUseCase
{
    public function __construct(
        private readonly AuthRepositoryInterface $repository,
        private readonly LogActivityUseCase $logActivity,
    ) {}

    public function execute(RegisterDTO $dto): array
    {
        $user = DB::transaction(fn () => $this->repository->createUser($dto));

        $token = auth('api')->login($user);

        $this->logActivity->execute(new LogActivityDTO(
            event: 'auth.registered',
            entityType: 'user',
            entityId: $user->user_id,
            tenantId: $user->tenant_id,
            userId: $user->user_id,
            payload: [
                'name'     => $user->name,
                'username' => $user->username,
                'email'    => $user->email,
            ],
        ));

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
            'expires_in' => auth('api')->factory()->getTTL() * 60,
        ];
    }
}
