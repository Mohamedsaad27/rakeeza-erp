<?php

namespace App\Modules\ActivityLog\Application\DTOs;

readonly class LogActivityDTO
{
    public function __construct(
        public string  $event,
        public string  $entityType,
        public string  $entityId,
        public string  $tenantId,
        public ?string $userId    = null,
        public array   $payload   = [],
        public ?string $ipAddress = null,
        public ?string $module    = null,
        public ?string $title     = null,
        public ?string $description = null,
    ) {}
}
