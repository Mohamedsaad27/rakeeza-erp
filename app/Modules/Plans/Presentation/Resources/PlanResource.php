<?php

namespace App\Modules\Plans\Presentation\Resources;

use App\Modules\Plans\Domain\Enums\BillingCycle;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PlanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $locale = app()->getLocale();
        $cycle  = BillingCycle::tryFrom((int) $this->billing_cycle);

        return [
            'id'             => $this->plan_id,
            'name_en'        => $this->name_en,
            'name_ar'        => $this->name_ar,
            'label'          => $locale === 'ar' ? $this->name_ar : $this->name_en,
            'price'          => $this->price,
            'billing_cycle'  => $this->billing_cycle,
            'billing_label'  => $cycle ? ($locale === 'ar' ? $cycle->labelAr() : $cycle->labelEn()) : null,
            'trial_days'     => $this->trial_days,
            'max_users'      => $this->max_users,
            'max_branches'   => $this->max_branches,
            'is_active'      => $this->is_active,
            'features_count' => $this->whenCounted('features'),
            'created_at'     => $this->created_at?->toIso8601String(),
        ];
    }
}
