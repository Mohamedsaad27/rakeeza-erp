<?php

namespace App\Modules\Inventory\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Inventory\Domain\Interfaces\InventoryRepositoryInterface;
use App\Modules\Inventory\Infrastructure\Persistence\Repositories\InventoryRepository;

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