<?php

namespace App\Modules\Roles\Presentation\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RoleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $locale = app()->getLocale();

        return [
            'id'              => $this->role_id,
            'name'            => $this->name,
            'name_en'         => $this->name_en,
            'name_ar'         => $this->name_ar,
            'label'           => $locale === 'ar' ? $this->name_ar : $this->name_en,
            'display_name_en' => $this->display_name_en,
            'display_name_ar' => $this->display_name_ar,
            'description_en'  => $this->description_en,
            'description_ar'  => $this->description_ar,
            'is_system'       => $this->is_system,
            'is_active'       => $this->is_active,
            'permissions_count' => $this->whenCounted('permissions'),
            'permissions'     => PermissionResource::collection($this->whenLoaded('permissions')),
            'created_at'      => $this->created_at?->toIso8601String(),
            'updated_at'      => $this->updated_at?->toIso8601String(),
        ];
    }
}
