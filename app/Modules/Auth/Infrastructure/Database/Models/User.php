<?php

namespace App\Modules\Auth\Infrastructure\Database\Models;

use App\Modules\Core\Infrastructure\Traits\BelongsToTenant;
use App\Modules\Core\Infrastructure\Traits\HasUuid;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Tymon\JWTAuth\Contracts\JWTSubject;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable implements JWTSubject
{
    use HasFactory, HasUuid, BelongsToTenant, HasRoles, Notifiable, SoftDeletes;

    protected static function newFactory(): UserFactory
    {
        return UserFactory::new();
    }

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
            'password'      => 'hashed',
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
        if ($this->tenant_id === null) {
            return ['guard' => 'platform'];
        }

        return [
            'tenant_id' => $this->tenant_id,
        ];
    }

    public function isPlatformUser(): bool
    {
        return $this->tenant_id === null;
    }

    protected function getDefaultGuardName(): string
    {
        return 'api';
    }
}
