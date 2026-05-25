<?php

namespace App\Modules\Features\Infrastructure\Providers;

use App\Modules\Features\Domain\Interfaces\FeatureRepositoryInterface;
use App\Modules\Features\Infrastructure\Persistence\Repositories\FeatureRepository;
use Illuminate\Support\ServiceProvider;

class RepositoryServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(FeatureRepositoryInterface::class, FeatureRepository::class);
    }
}
