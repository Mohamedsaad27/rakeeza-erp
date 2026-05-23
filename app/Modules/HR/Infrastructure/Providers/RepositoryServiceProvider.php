<?php

namespace App\Modules\HR\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\HR\Domain\Interfaces\HRRepositoryInterface;
use App\Modules\HR\Infrastructure\Persistence\Repositories\HRRepository;

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