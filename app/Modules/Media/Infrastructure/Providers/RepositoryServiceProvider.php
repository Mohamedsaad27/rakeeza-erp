<?php

namespace App\Modules\Media\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Media\Domain\Interfaces\MediaRepositoryInterface;
use App\Modules\Media\Infrastructure\Persistence\Repositories\MediaRepository;

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