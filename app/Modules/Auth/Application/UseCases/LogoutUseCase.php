<?php

namespace App\Modules\Auth\Application\UseCases;

use App\Modules\ActivityLog\Application\DTOs\LogActivityDTO;
use App\Modules\ActivityLog\Application\UseCases\LogActivityUseCase;

class LogoutUseCase
{
    public function __construct(
        private readonly LogActivityUseCase $logActivity,
    ) {}

    public function execute(string $guard): void
    {
        $user = auth($guard)->user();

        if ($user && $user->tenant_id) {
            $this->logActivity->execute(new LogActivityDTO(
                event: 'auth.logout',
                entityType: 'user',
                entityId: $user->user_id,
                tenantId: $user->tenant_id,
                userId: $user->user_id,
            ));
        }

        auth($guard)->logout(true);
    }
}
