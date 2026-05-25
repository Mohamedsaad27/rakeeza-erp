<?php

namespace App\Modules\Roles\Infrastructure\Database\Models;

use App\Modules\Core\Infrastructure\Traits\HasUuid;
use Illuminate\Database\Eloquent\Builder;
use Spatie\Permission\Models\Permission as SpatiePermission;

class Permission extends SpatiePermission
{
    use HasUuid;

    protected $primaryKey = 'permission_id';

    protected $fillable = [
        'tenant_id',
        'name',
        'guard_name',
        'module',
        'label_en',
        'label_ar',
        'description_en',
        'description_ar',
        'is_system',
    ];

    protected function casts(): array
    {
        return [
            'is_system' => 'boolean',
        ];
    }

    public function scopeAccessible(Builder $query, string $tenantId): Builder
    {
        return $query->where(function (Builder $builder) use ($tenantId) {
            $builder->whereNull('tenant_id')
                ->orWhere('tenant_id', $tenantId);
        });
    }

    public function isCustom(): bool
    {
        return $this->tenant_id !== null && ! $this->is_system;
    }
}
