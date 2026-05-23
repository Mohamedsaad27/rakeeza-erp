<?php

namespace App\Modules\Payments\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Payments\Domain\Interfaces\PaymentsRepositoryInterface;
use App\Modules\Payments\Infrastructure\Persistence\Repositories\PaymentsRepository;

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