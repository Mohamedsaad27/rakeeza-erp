<?php

namespace App\Modules\Plans\Application\UseCases;

use App\Modules\Plans\Domain\Interfaces\PlanRepositoryInterface;
use App\Modules\Plans\Domain\Enums\BillingCycle;

class GetPlanUseCase
{
    public function __construct(
        private readonly PlanRepositoryInterface $repository,
    ) {}

    public function execute(string $planId): array
    {
        $plan   = $this->repository->getWithRelations($planId);
        $locale = app()->getLocale();
        $cycle  = BillingCycle::tryFrom((int) $plan->billing_cycle);

        return [
            'id'            => $plan->plan_id,
            'name_en'       => $plan->name_en,
            'name_ar'       => $plan->name_ar,
            'label'         => $locale === 'ar' ? $plan->name_ar : $plan->name_en,
            'price'         => $plan->price,
            'billing_cycle' => $plan->billing_cycle,
            'billing_label' => $cycle ? ($locale === 'ar' ? $cycle->labelAr() : $cycle->labelEn()) : null,
            'trial_days'    => $plan->trial_days,
            'max_users'     => $plan->max_users,
            'max_branches'  => $plan->max_branches,
            'is_active'     => $plan->is_active,
            'features'      => $plan->features->map(fn ($f) => [
                'id'      => $f->feature_id,
                'code'    => $f->code,
                'label'   => $locale === 'ar' ? $f->name_ar : $f->name_en,
                'name_en' => $f->name_en,
                'name_ar' => $f->name_ar,
                'enabled' => (bool) $f->pivot->enabled,
            ])->values()->all(),
            'limits' => $plan->limits->map(fn ($l) => [
                'id'    => $l->plan_limit_id,
                'key'   => $l->key,
                'value' => $l->value,
            ])->values()->all(),
        ];
    }
}
