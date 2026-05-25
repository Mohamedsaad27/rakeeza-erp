<?php

namespace App\Modules\Features\Infrastructure\Database\Seeders;

use App\Modules\Features\Infrastructure\Database\Models\Feature;
use Illuminate\Database\Seeder;

class FeatureCatalogSeeder extends Seeder
{
    public function run(): void
    {
        $catalog = require __DIR__ . '/../../Config/features.php';

        foreach ($catalog as $item) {
            Feature::query()->updateOrCreate(
                ['code' => $item['code']],
                [
                    'name_en'        => $item['name_en'],
                    'name_ar'        => $item['name_ar'],
                    'description_en' => $item['description_en'] ?? null,
                    'description_ar' => $item['description_ar'] ?? null,
                    'is_active'      => true,
                ],
            );
        }
    }
}
