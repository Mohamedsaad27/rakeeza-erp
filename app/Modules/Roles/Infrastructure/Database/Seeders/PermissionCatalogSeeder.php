<?php

namespace App\Modules\Roles\Infrastructure\Database\Seeders;

use App\Modules\Roles\Infrastructure\Database\Models\Permission;
use Illuminate\Database\Seeder;

class PermissionCatalogSeeder extends Seeder
{
    public function run(): void
    {
        $catalog = require __DIR__ . '/../../Config/permissions.php';

        foreach ($catalog as $module => $moduleData) {
            foreach ($moduleData['permissions'] as $key => $labels) {
                Permission::query()->updateOrCreate(
                    [
                        'name'       => $key,
                        'guard_name' => 'api',
                        'tenant_id'  => null,
                    ],
                    [
                        'module'         => $module,
                        'label_en'       => $labels['label_en'],
                        'label_ar'       => $labels['label_ar'],
                        'description_en' => $labels['description_en'] ?? null,
                        'description_ar' => $labels['description_ar'] ?? null,
                        'is_system'      => true,
                    ],
                );
            }
        }
    }
}
