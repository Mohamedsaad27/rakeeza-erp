<?php

namespace App\Modules\Purchasing\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Purchasing\Domain\Interfaces\PurchasingRepositoryInterface;
use App\Modules\Purchasing\Infrastructure\Persistence\Repositories\PurchasingRepository;

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