<?php

namespace App\Modules\Features\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;

class FeaturesServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->register(RepositoryServiceProvider::class);
        $this->app->register(RouteServiceProvider::class);
    }

    public function boot(): void
    {
        $this->loadTranslationsFrom(
            __DIR__ . '/../../Presentation/Resources/Lang',
            'features',
        );
    }
}
