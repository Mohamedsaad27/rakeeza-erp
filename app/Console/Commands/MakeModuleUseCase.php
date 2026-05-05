<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

#[Signature('make:module-usecase {module} {name}')]
#[Description('Create a new UseCase inside a module — Usage: make:module-usecase Student StudentUseCase')]
class MakeModuleUseCase extends Command
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

        $filePath = "{$basePath}/Application/UseCases/{$name}.php";

        if (File::exists($filePath)) {
            $this->error("UseCase [{$name}] already exists ❌");
            return;
        }

        $content = <<<PHP
            <?php
             
            namespace App\\Modules\\{$module}\\Application\\UseCases;
             
            use App\\Modules\\{$module}\\Domain\\Interfaces\\{$module}RepositoryInterface;
            use App\\Modules\\{$module}\\Application\\DTOs\\{$name};
             
            class {$name}
            {
                public function __construct(
                    private readonly {$module}RepositoryInterface \$repository,
                ) {}
             
                public function execute({$name} \$data): mixed
                {
                    return \$this->repository->{$this->resolveRepositoryMethod($name)}(\$data);
                }
            }
            PHP;

        File::put($filePath, $content);

        $this->info("UseCase [{$name}] created successfully at Application/UseCases/ ✅");
    }

    private function resolveRepositoryMethod(string $name): string
    {
        $verb = Str::camel(preg_replace('/[A-Z]/', ' $0', $name));

        if (Str::startsWith(strtolower($verb), 'create'))
            return 'create';
        if (Str::startsWith(strtolower($verb), 'update'))
            return 'update';
        if (Str::startsWith(strtolower($verb), 'delete'))
            return 'delete';
        if (Str::startsWith(strtolower($verb), 'get') || Str::startsWith(strtolower($verb), 'find'))
            return 'findById';
        if (Str::startsWith(strtolower($verb), 'list') || Str::startsWith(strtolower($verb), 'get all'))
            return 'getAll';

        return 'handle';
    }
}
