<?php

namespace App\Modules\Roles\Presentation\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PermissionGroupResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'module'      => $this->resource['module'],
            'label_en'    => $this->resource['label_en'],
            'label_ar'    => $this->resource['label_ar'],
            'label'       => $this->resource['label'],
            'permissions' => $this->resource['permissions'],
        ];
    }
}
