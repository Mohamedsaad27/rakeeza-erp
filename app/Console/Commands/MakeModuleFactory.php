<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

#[Signature('make:module-factory {module} {name}')]
#[Description('Create a new Factory inside a module — Usage: make:module-factory Student StudentFactory')]
class MakeModuleFactory extends Command
{
    /**
     * Execute the console command.
     */
    public function handle(): void
    {
        $module = Str::studly($this->argument('module'));
        $name = Str::studly($this->argument('name'));
        $basePath = base_path("App/Modules/{$module}");

        if (!File::exists($basePath)) {
            $this->error("Module [{$module}] does not exist. Run make:module first ❌");
            return;
        }

        $filePath = "{$basePath}/Infrastructure/Database/Factories/{$name}.php";

        if (File::exists($filePath)) {
            $this->error("Factory [{$name}] already exists ❌");
            return;
        }

        $content = <<<PHP
            <?php
             
            namespace App\\Modules\\{$module}\\Infrastructure\\Database\\Factories;
             
            use Illuminate\\Database\\Eloquent\\Factories\\Factory;
            use App\\Modules\\{$module}\\Infrastructure\\Persistence\\Models\\{$name};
             
            class {$name} extends Factory
            {
                protected \$model = {$name}::class;
             
                public function definition(): array
                {
                    return [
                        //
                    ];
                }
            }
            PHP;

        File::put($filePath, $content);

        $this->info("Factory [{$name}] created successfully at Infrastructure/Database/Factories/ ✅");
    }
}
