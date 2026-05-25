<?php

namespace App\Modules\Auth\Infrastructure\Providers;

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
        Route::middleware(['api'])
            ->prefix('api/v1/auth')
            ->group(__DIR__ . '/../../Presentation/Routes/api.php');

        Route::middleware(['api'])
            ->prefix('api/v1/central/auth')
            ->group(__DIR__ . '/../../Presentation/Routes/central.php');
    }
}
