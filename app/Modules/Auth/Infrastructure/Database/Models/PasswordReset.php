<?php

namespace App\Modules\Auth\Infrastructure\Database\Models;

use App\Modules\Core\Infrastructure\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class PasswordReset extends Model
{
    use HasUuid;

    protected $table = 'password_resets';

    protected $primaryKey = 'password_reset_id';

    public $timestamps = false;

    protected $fillable = [
        'password_reset_id',
        'tenant_id',
        'email',
        'token',
        'created_at',
        'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'expires_at' => 'datetime',
        ];
    }
}
