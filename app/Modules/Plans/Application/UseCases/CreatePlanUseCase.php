<?php

namespace App\Modules\Plans\Application\UseCases;

use App\Modules\Plans\Application\DTOs\CreatePlanDTO;
use App\Modules\Plans\Domain\Interfaces\PlanRepositoryInterface;
use App\Modules\Plans\Domain\Enums\BillingCycle;

class CreatePlanUseCase
{
    public function __construct(
        private readonly PlanRepositoryInterface $repository,
    ) {}

    public function execute(CreatePlanDTO $dto): array
    {
        $plan = $this->repository->create($dto);

        return $this->formatPlan($plan);
    }

    public static function formatPlan(object $plan): array
    {
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
            'features_count'=> $plan->features_count ?? null,
        ];
    }
}
