<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

#[Signature('make:module-enum {module} {name}')]
#[Description('Create a new Enum inside a module — Usage: make:module-enum Student StudentEnum')]
class MakeModuleEnum extends Command
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
 
        $filePath = "{$basePath}/Domain/Enums/{$name}.php";
 
        if (File::exists($filePath)) {
            $this->error("Enum [{$name}] already exists ❌");
            return;
        }
 
        $content = <<<PHP
        <?php
 
        namespace App\Modules\\{$module}\Domain\Enums;
 
        enum {$name}: string
        {
            case Active   = 'active';
            case Inactive = 'inactive';
 
            public function label(): string
            {
                return match(\$this) {
                    self::Active   => 'Active',
                    self::Inactive => 'Inactive',
                };
            }
            public static function arabicLabels(): string
            {
                return match(\$this) {
                    self::Active   => 'نشط',
                    self::Inactive => 'غير نشط',
                };
            }
        }
        PHP;
 
        File::put($filePath, $content);
 
        $this->info("Enum [{$name}] created successfully at Domain/Enums/ ✅");
    }
}
