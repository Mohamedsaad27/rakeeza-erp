<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\File;
#[Signature('make:module-seeder {module} {name}')]
#[Description('Create a new Seeder inside a module — Usage: make:module-seeder Student StudentSeeder')]
class MakeModuleSeeder extends Command
{
    /**
     * Execute the console command.
     */
    public function handle(): void
    {
        $module   = Str::studly($this->argument('module'));
        $name     = Str::studly($this->argument('name'));
        $basePath = base_path("App/Modules/{$module}");
 
        if (!File::exists($basePath)) {
            $this->error("Module [{$module}] does not exist. Run make:module first ❌");
            return;
        }
 
        $filePath = "{$basePath}/Infrastructure/Database/Seeders/{$name}Seeder.php";
 
        if (File::exists($filePath)) {
            $this->error("Seeder [{$name}Seeder] already exists ❌");
            return;
        }
 
        $content = <<<PHP
        <?php
 
        namespace App\Modules\\{$module}\Infrastructure\Database\Seeders;
 
        use Illuminate\Database\Seeder;
        use App\Modules\\{$module}\Infrastructure\Persistence\Models\\{$name};
 
        class {$name}Seeder extends Seeder
        {
            public function run(): void
            {
                {$name}::factory()->count(10)->create();
            }
        }
        PHP;
 
        File::put($filePath, $content);
 
        $this->info("Seeder [{$name}Seeder] created successfully at Infrastructure/Database/Seeders/ ✅");
    }
}
