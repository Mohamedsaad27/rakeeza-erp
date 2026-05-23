<?php

namespace App\Modules\Sales\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Sales\Domain\Interfaces\SalesRepositoryInterface;
use App\Modules\Sales\Infrastructure\Persistence\Repositories\SalesRepository;

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