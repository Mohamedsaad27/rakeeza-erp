<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

class MakeModule extends Command
{
    protected $signature = 'make:module {name}';
    protected $description = 'Create a new module with clean architecture structure';

    public function handle(): void
    {
        $name = Str::studly($this->argument('name'));
        $basePath = base_path("app/Modules/{$name}");

        if (File::exists($basePath)) {
            $this->error("Module already exists ❌");
            return;
        }

        $this->createFolders($basePath);
        $this->createRouteFile($name, $basePath);
        $this->createRepositoryServiceProvider($name, $basePath);
        $this->createRouteServiceProvider($name, $basePath);
        $this->createModuleServiceProvider($name, $basePath);
        $this->createConfigFile($name, $basePath);
        $this->createModuleFile($name, $basePath);

        $this->info("Module {$name} created successfully ✅");
    }

    private function createFolders(string $basePath): void
    {
        $folders = [
            "Application/DTOs",
            "Application/Exceptions",
            "Application/UseCases",

            "Domain/Enums",
            "Domain/Interfaces",
            "Domain/Services",

            "Infrastructure/Database/Models",
            "Infrastructure/Database/Migrations",
            "Infrastructure/Database/Factories",
            "Infrastructure/Database/Seeders",
            "Infrastructure/Persistence",
            "Infrastructure/Providers",
            "Infrastructure/Config",
            "Infrastructure/Notifications",
            "Infrastructure/ExternalServices",

            "Presentation/Http/Controllers",
            "Presentation/Http/Requests",
            "Presentation/Http/Resources",
            "Presentation/Resources/Lang/en",
            "Presentation/Resources/Lang/ar",
            "Presentation/Routes",
        ];

        foreach ($folders as $folder) {
            File::makeDirectory("{$basePath}/{$folder}", 0755, true, true);
        }
    }

    private function createRouteFile(string $name, string $basePath): void
    {
        $prefix = $this->getRoutePrefix($name);

        $content = <<<PHP
        <?php

        use Illuminate\Support\Facades\Route;

        Route::prefix('{$prefix}')->group(function () {
            //
        });
        PHP;

        File::put("{$basePath}/Presentation/Routes/api.php", $content);
    }
    private function createConfigFile(string $name, string $basePath): void
    {
        $content = <<<PHP
        <?php
        return [
            'name' => '{$name}',
            'alias' => '{$name}',
        ];
        PHP;

        File::put("{$basePath}/Infrastructure/Config/config.php", $content);
    }

    private function createRepositoryServiceProvider(string $name, string $basePath): void
    {
        $content = <<<PHP
        <?php

        namespace App\Modules\\{$name}\Infrastructure\Providers;

        use Illuminate\Support\ServiceProvider;

        class RepositoryServiceProvider extends ServiceProvider
        {
            public function register(): void
            {
                // Bind repository interfaces to implementations here
                // Example:
                // \$this->app->bind(
                //     \\App\\Modules\\{$name}\\Domain\\Interfaces\\{$name}RepositoryInterface::class,
                //     \\App\\Modules\\{$name}\\Infrastructure\\Persistence\\{$name}Repository::class,
                // );
            }

            public function boot(): void
            {
                //
            }
        }
        PHP;

        File::put("{$basePath}/Infrastructure/Providers/RepositoryServiceProvider.php", $content);
    }

    private function createRouteServiceProvider(string $name, string $basePath): void
    {
        $content = <<<PHP
        <?php

        namespace App\Modules\\{$name}\Infrastructure\Providers;

        use Illuminate\Support\ServiceProvider;

        class RouteServiceProvider extends ServiceProvider
        {
            public function register(): void
            {
                //
            }

            public function boot(): void
            {
                \$this->loadRoutesFrom(__DIR__ . '/../../Presentation/Routes/api.php');
            }
        }
        PHP;

        File::put("{$basePath}/Infrastructure/Providers/RouteServiceProvider.php", $content);
    }

    private function createModuleServiceProvider(string $name, string $basePath): void
    {
        $providerName = "{$name}ServiceProvider";

        $content = <<<PHP
        <?php

        namespace App\Modules\\{$name}\Infrastructure\Providers;

        use Illuminate\Support\ServiceProvider;

        class {$providerName} extends ServiceProvider
        {
            public function register(): void
            {
                \$this->app->register(RepositoryServiceProvider::class);
                \$this->app->register(RouteServiceProvider::class);
            }

            public function boot(): void
            {
                //
            }
        }
        PHP;

        File::put("{$basePath}/Infrastructure/Providers/{$providerName}.php", $content);
    }

    private function createModuleFile(string $name, string $basePath): void
    {
        $provider = "App\\\\Modules\\\\{$name}\\\\Infrastructure\\\\Providers\\\\{$name}ServiceProvider";
 
        $content = <<<JSON
        {
            "name": "{$name}",
            "alias": "{$name}",
            "description": "{$name} module",
            "keywords": [
                "{$name}"
            ],
            "priority": 0,
            "providers": [
                "{$provider}"
            ],
            "files": []
        }
        JSON;
 
        File::put("{$basePath}/module.json", $content);
    }
 

    private function getRoutePrefix(string $name): string
    {
        return Str::kebab($name);
    }
}