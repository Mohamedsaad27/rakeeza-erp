<?php

namespace Database\Seeders;

use App\Modules\Auth\Infrastructure\Database\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::factory()->platformAdmin()->create([
            'name'     => 'Test User',
            'username' => 'testuser',
            'email'    => 'test@example.com',
        ]);
    }
}
