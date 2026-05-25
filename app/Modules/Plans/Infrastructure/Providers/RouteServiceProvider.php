<?php

namespace App\Modules\Plans\Infrastructure\Providers;

use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

class RouteServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Route::middleware(['api', 'auth:platform'])
            ->prefix('api/v1/central/plans')
            ->group(__DIR__ . '/../../Presentation/Routes/central.php');
    }
}
