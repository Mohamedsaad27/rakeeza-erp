<?php

namespace App\Modules\ActivityLog\Infrastructure\Database\Models;

use App\Modules\Core\Infrastructure\Traits\BelongsToTenant;
use App\Modules\Core\Infrastructure\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class TenantAuditLog extends Model
{
    use HasUuid, BelongsToTenant;

    protected $table = 'activity_log';

    protected $primaryKey = 'activity_lo_id';

    public $timestamps = false;

    protected $fillable = [
        'tenant_id',
        'user_id',
        'subject_id',
        'subject_type',
        'event',
        'module',
        'description',
        'title',
        'properties',
        'ip_address',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'properties' => 'array',
            'created_at' => 'datetime',
        ];
    }
}
