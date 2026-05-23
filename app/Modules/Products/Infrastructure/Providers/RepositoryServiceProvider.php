<?php

namespace App\Modules\Products\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Products\Domain\Interfaces\ProductsRepositoryInterface;
use App\Modules\Products\Infrastructure\Persistence\Repositories\ProductsRepository;

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