<?php

namespace App\Modules\Finance\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Finance\Domain\Interfaces\FinanceRepositoryInterface;
use App\Modules\Finance\Infrastructure\Persistence\Repositories\FinanceRepository;

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