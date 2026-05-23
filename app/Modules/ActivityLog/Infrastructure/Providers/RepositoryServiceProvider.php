<?php

namespace App\Modules\ActivityLog\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\ActivityLog\Domain\Interfaces\ActivityLogRepositoryInterface;
use App\Modules\ActivityLog\Infrastructure\Persistence\Repositories\ActivityLogRepository;

class RepositoryServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            \App\Modules\ActivityLog\Domain\Interfaces\ActivityLogRepositoryInterface::class,
            \App\Modules\ActivityLog\Infrastructure\Persistence\ActivityLogRepository::class,
        );
    }

    public function boot(): void
    {
        //
    }
}