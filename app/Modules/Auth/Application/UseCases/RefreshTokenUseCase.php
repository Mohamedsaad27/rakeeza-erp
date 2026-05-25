<?php

namespace App\Modules\Auth\Application\UseCases;

class RefreshTokenUseCase
{
    public function execute(string $guard): array
    {
        $token = auth($guard)->refresh();
        $user  = auth($guard)->user();

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
