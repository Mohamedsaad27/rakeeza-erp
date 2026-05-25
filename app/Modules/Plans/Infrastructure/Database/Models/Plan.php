<?php

namespace App\Modules\Plans\Infrastructure\Database\Models;

use App\Modules\Core\Infrastructure\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Plan extends Model
{
    use HasUuid, SoftDeletes;

    protected $table = 'plans';

    protected $primaryKey = 'plan_id';

    protected $fillable = [
        'name_en',
        'name_ar',
        'price',
        'billing_cycle',
        'trial_days',
        'max_users',
        'max_branches',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'price'         => 'decimal:4',
            'billing_cycle' => 'integer',
            'trial_days'    => 'integer',
            'max_users'     => 'integer',
            'max_branches'  => 'integer',
            'is_active'     => 'boolean',
        ];
    }

    public function limits(): HasMany
    {
        return $this->hasMany(PlanLimit::class, 'plan_id', 'plan_id');
    }

    public function features(): BelongsToMany
    {
        return $this->belongsToMany(
            \App\Modules\Features\Infrastructure\Database\Models\Feature::class,
            'plan_features',
            'plan_id',
            'feature_id',
            'plan_id',
            'feature_id',
        )->withPivot(['enabled', 'plan_feature_id']);
    }
}
