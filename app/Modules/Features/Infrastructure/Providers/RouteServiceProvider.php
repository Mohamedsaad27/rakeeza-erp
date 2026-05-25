<?php

namespace App\Modules\Features\Infrastructure\Providers;

use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

class RouteServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Route::middleware(['api', 'auth:platform'])
            ->prefix('api/v1/central/features')
            ->group(__DIR__ . '/../../Presentation/Routes/central.php');
    }
}
