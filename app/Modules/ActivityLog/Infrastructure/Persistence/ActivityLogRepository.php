<?php

namespace App\Modules\ActivityLog\Infrastructure\Persistence;

use App\Modules\ActivityLog\Application\DTOs\LogActivityDTO;
use App\Modules\ActivityLog\Domain\Interfaces\ActivityLogRepositoryInterface;
use App\Modules\ActivityLog\Infrastructure\Database\Models\TenantAuditLog;
use Illuminate\Support\Facades\Log;

class ActivityLogRepository implements ActivityLogRepositoryInterface
{
    public function logTenantActivity(LogActivityDTO $dto): void
    {
        try {
            TenantAuditLog::withoutGlobalScopes()->create([
                'tenant_id'    => $dto->tenantId,
                'user_id'      => $dto->userId,
                'subject_id'   => $dto->entityId,
                'subject_type' => $dto->entityType,
                'event'        => $dto->event,
                'module'       => $dto->module,
                'title'        => $dto->title ?? $dto->event,
                'description'  => $dto->description,
                'properties'   => $dto->payload,
                'ip_address'   => $dto->ipAddress,
                'created_at'   => now(),
            ]);
        } catch (\Throwable $e) {
            Log::error('ActivityLog write failed', [
                'error' => $e->getMessage(),
                'dto'   => (array) $dto,
            ]);
        }
    }
}
