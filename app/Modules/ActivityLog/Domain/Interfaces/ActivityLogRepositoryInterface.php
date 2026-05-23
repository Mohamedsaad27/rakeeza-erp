<?php

namespace App\Modules\ActivityLog\Domain\Interfaces;

use App\Modules\ActivityLog\Application\DTOs\LogActivityDTO;

interface ActivityLogRepositoryInterface
{
    public function logTenantActivity(LogActivityDTO $dto): void;
}
