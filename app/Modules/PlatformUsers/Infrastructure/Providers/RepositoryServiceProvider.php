<?php

namespace App\Modules\PlatformUsers\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\PlatformUsers\Domain\Interfaces\PlatformUsersRepositoryInterface;
use App\Modules\PlatformUsers\Infrastructure\Persistence\Repositories\PlatformUsersRepository;

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