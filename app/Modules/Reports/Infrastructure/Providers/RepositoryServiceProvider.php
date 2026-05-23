<?php

namespace App\Modules\Reports\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Reports\Domain\Interfaces\ReportsRepositoryInterface;
use App\Modules\Reports\Infrastructure\Persistence\Repositories\ReportsRepository;

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