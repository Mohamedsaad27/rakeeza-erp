<?php

namespace App\Modules\Auth\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Auth\Domain\Interfaces\AuthRepositoryInterface;
use App\Modules\Auth\Infrastructure\Persistence\Repositories\AuthRepository;

class RepositoryServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            AuthRepositoryInterface::class,
            AuthRepository::class,
        );
    }

    public function boot(): void
    {
        //
    }
}