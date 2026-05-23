<?php

namespace App\Modules\Settings\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Settings\Domain\Interfaces\SettingsRepositoryInterface;
use App\Modules\Settings\Infrastructure\Persistence\Repositories\SettingsRepository;

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