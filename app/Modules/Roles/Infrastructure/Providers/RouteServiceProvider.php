<?php

namespace App\Modules\Roles\Infrastructure\Providers;

use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

class RouteServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        Route::middleware(['api', 'auth:api', 'scope.tenant'])
            ->prefix('api/v1/roles')
            ->group(__DIR__ . '/../../Presentation/Routes/api.php');

        Route::middleware(['api', 'auth:api', 'scope.tenant'])
            ->prefix('api/v1/permissions')
            ->group(__DIR__ . '/../../Presentation/Routes/permissions.php');
    }
}
