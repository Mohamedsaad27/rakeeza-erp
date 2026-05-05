<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

#[Signature('make:module-request {module} {name}')]
#[Description('Create a new Request inside a module — Usage: make:module-request Student StudentRequest')]
class MakeModuleRequest extends Command
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

        $filePath = "{$basePath}/Presentation/Http/Requests/{$name}.php";

        if (File::exists($filePath)) {
            $this->error("Request [{$name}] already exists ❌");
            return;
        }

        $dtoName = Str::studly(preg_replace('/^(Create|Update|Delete|Get)/i', '', $name));

        $content = <<<PHP
            <?php
             
            namespace App\\Modules\\{$module}\\Presentation\\Http\\Requests;
             
            use Illuminate\\Foundation\\Http\\FormRequest;
            use App\\Modules\\{$module}\\Application\\DTOs\\{$name}DTO;
             
            class {$name} extends FormRequest
            {
                public function authorize(): bool
                {
                    return true;
                }
             
                public function rules(): array
                {
                    return [
                        //
                    ];
                }
             
                public function toDTO(): {$name}DTO
                {
                    return {$name}DTO::fromArray(\$this->validated());
                }
                public function messages(): array
                {
                    return [
                        //
                    ];
                }   
            }
            PHP;

        File::put($filePath, $content);

        $this->info("Request [{$name}] created successfully at Presentation/Http/Requests/ ✅");
    }
}
