<?php

namespace App\Modules\Features\Infrastructure\Database\Models;

use App\Modules\Core\Infrastructure\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Feature extends Model
{
    use HasUuid;

    protected $table = 'features';

    protected $primaryKey = 'feature_id';

    protected $fillable = [
        'name_en',
        'name_ar',
        'code',
        'description_en',
        'description_ar',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }
}
