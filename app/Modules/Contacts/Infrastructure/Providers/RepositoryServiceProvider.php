<?php

namespace App\Modules\Contacts\Infrastructure\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Contacts\Domain\Interfaces\ContactsRepositoryInterface;
use App\Modules\Contacts\Infrastructure\Persistence\Repositories\ContactsRepository;

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