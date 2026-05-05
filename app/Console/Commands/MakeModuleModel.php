<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

#[Signature('make:module-model {module} {name}')]
#[Description('Create a new Model inside a module — Usage: make:module-model Student Student')]
class MakeModuleModel extends Command
{
    /**
     * Execute the console command.
     */
     public function handle(): void
    {
        $module    = Str::studly($this->argument('module'));
        $name      = Str::studly($this->argument('name'));
        $table     = Str::snake(Str::plural($name));
        $basePath  = base_path("App/Modules/{$module}");
 
        if (!File::exists($basePath)) {
            $this->error("Module [{$module}] does not exist. Run make:module first ❌");
            return;
        }
 
        $filePath = "{$basePath}/Infrastructure/Persistence/Models/{$name}.php";
 
        if (File::exists($filePath)) {
            $this->error("Model [{$name}] already exists ❌");
            return;
        }
 
        $content = <<<PHP
        <?php
 
        namespace App\Modules\\{$module}\Infrastructure\Persistence\Models;
 
        use Illuminate\Database\Eloquent\Model;
        use Illuminate\Database\Eloquent\Factories\HasFactory;
        use Illuminate\Database\Eloquent\SoftDeletes;
 
        class {$name} extends Model
        {
            use HasFactory, SoftDeletes;
 
            protected \$table = '{$table}';
 
            protected \$fillable = [
                //
            ];
 
            protected \$casts = [
                //
            ];
 
            protected \$hidden = [
                //
            ];
        }
        PHP;
 
        File::put($filePath, $content);
 
        $this->info("Model [{$name}] created successfully at Infrastructure/Persistence/Models/ ✅");
    }
}
