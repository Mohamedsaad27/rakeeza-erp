<?php

namespace App\Modules\Auth\Infrastructure\Database\Models;

use App\Modules\Core\Infrastructure\Traits\BelongsToTenant;
use App\Modules\Core\Infrastructure\Traits\HasUuid;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use PHPOpenSourceSaver\JWTAuth\Contracts\JWTSubject;

class User extends Authenticatable implements JWTSubject
{
    use HasUuid, BelongsToTenant, Notifiable;

    protected $table = 'users';

    protected $primaryKey = 'user_id';

    protected $fillable = [
        'tenant_id',
        'branch_id',
        'name',
        'username',
        'email',
        'phone',
        'avatar',
        'password',
        'fcm_token',
        'is_active',
        'last_login_at',
        'verified_at',
    ];

    protected $hidden = [
        'password',
    ];

    protected function casts(): array
    {
        return [
            'is_active'     => 'boolean',
            'last_login_at' => 'datetime',
            'verified_at'   => 'datetime',
        ];
    }

    public function getJWTIdentifier(): mixed
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims(): array
    {
        return [
            'tenant_id' => $this->tenant_id,
        ];
    }
}
