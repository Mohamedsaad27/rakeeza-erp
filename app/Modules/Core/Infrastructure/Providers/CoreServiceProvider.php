<?php

namespace App\Modules\Core\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;

class CoreServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // 3. Auto-discover and register all module ServiceProviders
        $this->app->register(ModuleServiceProvider::class);

        // 4. Repository interface → implementation bindings
        $this->app->register(RepositoryServiceProvider::class);

        // 5. Core module routes (health-check, shared endpoints)
        $this->app->register(RouteServiceProvider::class);
    }

    public function boot(): void
    {
        //
    }
}