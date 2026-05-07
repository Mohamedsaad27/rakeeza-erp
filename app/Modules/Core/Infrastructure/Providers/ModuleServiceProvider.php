<?php

namespace App\Modules\Core\Infrastructure\Providers;

use Illuminate\Support\Facades\File;
use Illuminate\Support\ServiceProvider;

class ModuleServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->registerModuleProviders();
    }

    public function boot(): void
    {
        //
    }

    protected function registerModuleProviders(): void
    {
        $modulesPath = app_path('Modules');

        if (! File::exists($modulesPath)) {
            return;
        }

        foreach (File::directories($modulesPath) as $module) {
            $moduleName = basename($module);

            // Skip Core — it bootstraps everything
            if ($moduleName === 'Core') {
                continue;
            }

            $serviceProviderPath = "$module/Infrastructure/Providers/{$moduleName}ServiceProvider.php";

            if (File::exists($serviceProviderPath)) {
                $providerClass = "App\\Modules\\{$moduleName}\\Infrastructure\\Providers\\{$moduleName}ServiceProvider";

                if (class_exists($providerClass)) {
                    $this->app->register($providerClass);
                }
            }

            // Optional: module.json support
            $moduleJsonPath = "$module/module.json";
            if (File::exists($moduleJsonPath)) {
                $moduleConfig = json_decode(File::get($moduleJsonPath), true);
                foreach ($moduleConfig['providers'] ?? [] as $provider) {
                    if (class_exists($provider)) {
                        $this->app->register($provider);
                    }
                }
            }
        }
    }
}
