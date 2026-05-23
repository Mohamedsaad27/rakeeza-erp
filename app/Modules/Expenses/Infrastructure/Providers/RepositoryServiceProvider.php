<?php

namespace App\Modules\Expenses\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Expenses\Domain\Interfaces\ExpensesRepositoryInterface;
use App\Modules\Expenses\Infrastructure\Persistence\Repositories\ExpensesRepository;

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