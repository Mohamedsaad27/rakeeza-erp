<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

#[Signature('make:module-controller {module} {name}')]
#[Description('Create a new Controller inside a module — Usage: make:module-controller Teacher Teache')]
class MakeModuleController extends Command
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

        $filePath = "{$basePath}/Presentation/Http/Controllers/{$name}.php";

        if (File::exists($filePath)) {
            $this->error("Controller [{$name}] already exists ❌");
            return;
        }

        $content = <<<PHP
            <?php
             
            namespace App\\Modules\\{$module}\Presentation\Http\Controllers;
            class {$name} extends Controller
            {
                
            }
            PHP;

        File::put($filePath, $content);

        $this->info("Controller [{$name}] created successfully at Presentation/Http/Controllers/ ✅");
    }
}
