<?php

namespace App\Modules\Features\Presentation\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FeatureResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $locale = app()->getLocale();

        return [
            'id'             => $this->feature_id,
            'code'           => $this->code,
            'name_en'        => $this->name_en,
            'name_ar'        => $this->name_ar,
            'label'          => $locale === 'ar' ? $this->name_ar : $this->name_en,
            'description_en' => $this->description_en,
            'description_ar' => $this->description_ar,
            'is_active'      => $this->is_active,
            'created_at'     => $this->created_at?->toIso8601String(),
            'updated_at'     => $this->updated_at?->toIso8601String(),
        ];
    }
}
