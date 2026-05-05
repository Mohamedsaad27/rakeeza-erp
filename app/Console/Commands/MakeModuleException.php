<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

#[Signature('make:module-exception {module} {name}')]
#[Description('Create a new Exception inside a module — Usage: make:module-exception Student StudentNotFoundException')]
class MakeModuleException extends Command
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

        $filePath = "{$basePath}/Application/Exceptions/{$name}.php";

        if (File::exists($filePath)) {
            $this->error("Exception [{$name}] already exists ❌");
            return;
        }

        $httpStatus = $this->resolveHttpStatus($name);

        $content = <<<PHP
            <?php
             
            namespace App\\Modules\\{$module}\Application\Exceptions;
             
            use App\Application\Exceptions\BaseException;
             
            class {$name}Exception extends BaseException
            {
                public function __construct(
                    string \$message = '{$this->resolveMessage($name)}',
                    int \$code = {$httpStatus},
                ) {
                    parent::__construct(\$message, \$code);
                }
             
                public function getDefaultMessage(): string
                {
                    return \$this->getMessage();
                }

                public function getDefaultStatusCode(): int
                {
                    return \$this->getCode();
                }
            }
            PHP;

        File::put($filePath, $content);

        $this->info("Exception [{$name}] created successfully at Application/Exceptions/ ✅");
    }

    private function resolveHttpStatus(string $name): int
    {
        $lower = strtolower($name);

        if (str_contains($lower, 'notfound') || str_contains($lower, 'not_found'))
            return 404;
        if (str_contains($lower, 'unauthorized'))
            return 401;
        if (str_contains($lower, 'forbidden'))
            return 403;
        if (str_contains($lower, 'invalid') || str_contains($lower, 'validation'))
            return 422;
        if (str_contains($lower, 'conflict') || str_contains($lower, 'duplicate'))
            return 409;

        return 400;
    }

    private function resolveMessage(string $name): string
    {
        return Str::headline($name) . '.';
    }
}
