<?php

namespace App\Modules\Plans\Infrastructure\Providers;

use App\Modules\Plans\Domain\Interfaces\PlanRepositoryInterface;
use App\Modules\Plans\Infrastructure\Persistence\Repositories\PlanRepository;
use Illuminate\Support\ServiceProvider;

class RepositoryServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(PlanRepositoryInterface::class, PlanRepository::class);
    }
}
