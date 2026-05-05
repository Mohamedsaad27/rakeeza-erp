<?php

namespace App\Modules\Core\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Core\Domain\Interfaces\CoreRepositoryInterface;
use App\Modules\Core\Infrastructure\Persistence\Repositories\CoreRepository;

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