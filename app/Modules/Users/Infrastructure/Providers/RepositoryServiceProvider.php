<?php

namespace App\Modules\Users\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;

class RepositoryServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Bind repository interfaces to implementations here
        // Example:
        // $this->app->bind(
        //     \App\Modules\Users\Domain\Interfaces\UsersRepositoryInterface::class,
        //     \App\Modules\Users\Infrastructure\Persistence\UsersRepository::class,
        // );
    }

    public function boot(): void
    {
        //
    }
}