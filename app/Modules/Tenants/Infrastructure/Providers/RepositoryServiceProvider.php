<?php

namespace App\Modules\Tenants\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Tenants\Domain\Interfaces\TenantsRepositoryInterface;
use App\Modules\Tenants\Infrastructure\Persistence\Repositories\TenantsRepository;

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