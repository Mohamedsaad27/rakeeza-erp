<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

#[Signature('make:module-dto {module} {name}')]
#[Description('Create a new DTO inside a module — Usage: make:module-dto Student CreateStudentDTO')]
class MakeModuleDto extends Command
{
    public function handle(): void
    {
        $module = Str::studly($this->argument('module'));
        $name = Str::studly($this->argument('name'));
        $basePath = base_path("App/Modules/{$module}");

        if (!File::exists($basePath)) {
            $this->error("Module [{$module}] does not exist. Run make:module first ❌");
            return;
        }

        $filePath = "{$basePath}/Application/DTOs/{$name}.php";

        if (File::exists($filePath)) {
            $this->error("DTO [{$name}] already exists ❌");
            return;
        }

        $content = <<<PHP
            <?php
             
            namespace App\\Modules\\{$module}\Application\DTOs;
             
            class {$name}
            {
               
            }
            PHP;

        File::put($filePath, $content);

        $this->info("DTO [{$name}] created successfully at Application/DTOs/ ✅");
    }
}
