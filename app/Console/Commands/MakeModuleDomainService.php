<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

#[Signature('make:module-service {module} {name}')]
#[Description('Create a new Domain Service inside a module — Usage: make:module-service Teacher TeacherEligibility')]
class MakeModuleDomainService extends Command
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

        $filePath = "{$basePath}/Domain/Services/{$name}.php";

        if (File::exists($filePath)) {
            $this->error("Domain Service [{$name}] already exists ❌");
            return;
        }

        $content = <<<PHP
            <?php
             
            namespace App\\Modules\\{$module}\\Domain\\Services;
             
            use App\\Modules\\{$module}\\Domain\\Interfaces\\{$module}RepositoryInterface;
             
            class {$name}
            {
                public function __construct(
                    private readonly {$module}RepositoryInterface \$repository,
                ) {}
                    // Domain logic here — no HTTP, no Eloquent, pure business rules
            }
            PHP;

        File::put($filePath, $content);

        $this->info("Domain Service [{$name}] created successfully at Domain/Services/ ✅");
    }
}
