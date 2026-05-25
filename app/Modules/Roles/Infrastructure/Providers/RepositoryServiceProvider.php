<?php

namespace App\Modules\Roles\Infrastructure\Providers;

use App\Modules\Roles\Domain\Interfaces\PermissionRepositoryInterface;
use App\Modules\Roles\Domain\Interfaces\RoleRepositoryInterface;
use App\Modules\Roles\Infrastructure\Persistence\Repositories\PermissionRepository;
use App\Modules\Roles\Infrastructure\Persistence\Repositories\RoleRepository;
use Illuminate\Support\ServiceProvider;

class RepositoryServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(RoleRepositoryInterface::class, RoleRepository::class);
        $this->app->bind(PermissionRepositoryInterface::class, PermissionRepository::class);
    }

    public function boot(): void
    {
        //
    }
}
