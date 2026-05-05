<?php

namespace App\Modules\ActivityLog\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\ActivityLog\Domain\Interfaces\ActivityLogRepositoryInterface;
use App\Modules\ActivityLog\Infrastructure\Persistence\Repositories\ActivityLogRepository;

class RepositoryServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        
    }

    public function boot(): void
    {
        //
    }
}