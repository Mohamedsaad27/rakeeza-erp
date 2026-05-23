<?php

namespace App\Modules\PlatformUsers\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;

class PlatformUsersServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->register(RepositoryServiceProvider::class);
        $this->app->register(RouteServiceProvider::class);
    }

    public function boot(): void
    {
        //
    }
}