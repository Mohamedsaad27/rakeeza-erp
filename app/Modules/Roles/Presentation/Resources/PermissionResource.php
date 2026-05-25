<?php

namespace App\Modules\Roles\Presentation\Resources;

use App\Modules\Roles\Domain\Services\PermissionCatalogService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PermissionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $catalogService = app(PermissionCatalogService::class);

        return [
            'id'             => $this->permission_id,
            'key'            => $this->name,
            'label_en'       => $this->label_en,
            'label_ar'       => $this->label_ar,
            'label'          => $catalogService->resolveLabel($this->resource),
            'module'         => $this->module,
            'description_en' => $this->description_en,
            'description_ar' => $this->description_ar,
            'is_system'      => $this->is_system,
            'is_custom'      => $this->resource->isCustom(),
        ];
    }
}
