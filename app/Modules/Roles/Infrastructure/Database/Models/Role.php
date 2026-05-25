<?php

namespace App\Modules\Roles\Infrastructure\Database\Models;

use App\Modules\Core\Infrastructure\Traits\BelongsToTenant;
use App\Modules\Core\Infrastructure\Traits\HasUuid;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\Permission\Models\Role as SpatieRole;

class Role extends SpatieRole
{
    use BelongsToTenant, HasUuid, SoftDeletes;

    protected $primaryKey = 'role_id';

    protected $fillable = [
        'tenant_id',
        'name',
        'guard_name',
        'name_en',
        'name_ar',
        'display_name_en',
        'display_name_ar',
        'description_en',
        'description_ar',
        'is_system',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_system' => 'boolean',
            'is_active' => 'boolean',
        ];
    }
}
