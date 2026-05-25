<?php

namespace App\Modules\Roles\Domain\Services;

class PermissionCatalogService
{
    public function resolveLabel(object $permission): string
    {
        $locale = app()->getLocale();

        return $locale === 'ar'
            ? ($permission->label_ar ?? $permission->label_en)
            : ($permission->label_en ?? $permission->label_ar);
    }

    public function resolveModuleLabel(string $module): array
    {
        $catalog = require dirname(__DIR__, 2) . '/Infrastructure/Config/permissions.php';
        $moduleData = $catalog[$module] ?? null;

        if (! $moduleData) {
            return [
                'label_en' => ucfirst($module),
                'label_ar' => ucfirst($module),
                'label'    => ucfirst($module),
            ];
        }

        $locale = app()->getLocale();

        return [
            'label_en' => $moduleData['label_en'],
            'label_ar' => $moduleData['label_ar'],
            'label'    => $locale === 'ar' ? $moduleData['label_ar'] : $moduleData['label_en'],
        ];
    }
}
