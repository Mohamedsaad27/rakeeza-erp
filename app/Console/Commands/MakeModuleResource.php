<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

#[Signature('make:module-resource {module} {name}')]
#[Description('Create a new Resource inside a module — Usage: make:module-resource Student StudentResource')]
class MakeModuleResource extends Command
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

        $filePath = "{$basePath}/Presentation/Http/Resources/{$name}.php";

        if (File::exists($filePath)) {
            $this->error("Resource [{$name}] already exists ❌");
            return;
        }

        $content = <<<PHP
            <?php
             
            namespace App\\Modules\\{$module}\Presentation\Http\Resources;
             
            use Illuminate\Http\Request;
            use Illuminate\Http\Resources\Json\JsonResource;
             
            class {$name} extends JsonResource
            {
                public function toArray(Request \$request): array
                {
                    return [
                        'id'         => \$this->id,
                        'created_at' => \$this->created_at,
                        'updated_at' => \$this->updated_at,
                    ];
                }
            }
            PHP;

        File::put($filePath, $content);

        $this->info("Resource [{$name}] created successfully at Presentation/Http/Resources/ ✅");
    }
}
