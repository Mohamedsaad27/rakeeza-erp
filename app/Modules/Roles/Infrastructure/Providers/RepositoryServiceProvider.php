<?php

namespace App\Modules\Roles\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;

class RepositoryServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Bind repository interfaces to implementations here
        // Example:
        // $this->app->bind(
        //     \App\Modules\Roles\Domain\Interfaces\RolesRepositoryInterface::class,
        //     \App\Modules\Roles\Infrastructure\Persistence\RolesRepository::class,
        // );
    }

    public function boot(): void
    {
        //
    }
}