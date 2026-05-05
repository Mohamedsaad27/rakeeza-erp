<?php

namespace App\Modules\Notifications\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Notifications\Domain\Interfaces\NotificationsRepositoryInterface;
use App\Modules\Notifications\Infrastructure\Persistence\Repositories\NotificationsRepository;

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