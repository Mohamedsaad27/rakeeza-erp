<?php

namespace App\Modules\Plans\Infrastructure\Persistence\Repositories;

use App\Modules\Plans\Application\DTOs\CreatePlanDTO;
use App\Modules\Plans\Application\DTOs\UpdatePlanDTO;
use App\Modules\Plans\Domain\Interfaces\PlanRepositoryInterface;
use App\Modules\Plans\Infrastructure\Database\Models\Plan;
use App\Modules\Plans\Infrastructure\Database\Models\PlanLimit;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PlanRepository implements PlanRepositoryInterface
{
    public function paginate(int $perPage = 15): LengthAwarePaginator
    {
        return Plan::query()
            ->withCount('features')
            ->orderBy('price')
            ->paginate($perPage);
    }

    public function findById(string $planId): Plan
    {
        return Plan::query()->where('plan_id', $planId)->firstOrFail();
    }

    public function getWithRelations(string $planId): Plan
    {
        return Plan::query()
            ->with(['features', 'limits'])
            ->where('plan_id', $planId)
            ->firstOrFail();
    }

    public function create(CreatePlanDTO $dto): Plan
    {
        return Plan::create([
            'name_en'       => $dto->nameEn,
            'name_ar'       => $dto->nameAr,
            'price'         => $dto->price,
            'billing_cycle' => $dto->billingCycle,
            'trial_days'    => $dto->trialDays,
            'max_users'     => $dto->maxUsers,
            'max_branches'  => $dto->maxBranches,
            'is_active'     => $dto->isActive,
        ]);
    }

    public function update(Plan $plan, UpdatePlanDTO $dto): Plan
    {
        $plan->update(array_filter([
            'name_en'       => $dto->nameEn,
            'name_ar'       => $dto->nameAr,
            'price'         => $dto->price,
            'billing_cycle' => $dto->billingCycle,
            'trial_days'    => $dto->trialDays,
            'max_users'     => $dto->maxUsers,
            'max_branches'  => $dto->maxBranches,
            'is_active'     => $dto->isActive,
        ], fn ($v) => $v !== null));

        return $plan->fresh(['features', 'limits']);
    }

    public function delete(Plan $plan): void
    {
        $plan->delete();
    }

    public function syncFeatures(Plan $plan, array $featureSync): void
    {
        DB::table('plan_features')->where('plan_id', $plan->plan_id)->delete();

        foreach ($featureSync as $featureId => $enabled) {
            DB::table('plan_features')->insert([
                'plan_feature_id' => (string) Str::uuid(),
                'plan_id'         => $plan->plan_id,
                'feature_id'      => $featureId,
                'enabled'         => (bool) $enabled,
            ]);
        }
    }

    public function syncLimits(Plan $plan, array $limits): void
    {
        PlanLimit::query()->where('plan_id', $plan->plan_id)->delete();

        foreach ($limits as $key => $value) {
            PlanLimit::create([
                'plan_id' => $plan->plan_id,
                'key'     => $key,
                'value'   => (int) $value,
            ]);
        }
    }

    public function isUsedByTenants(string $planId): bool
    {
        return DB::table('tenants')->where('plan_id', $planId)->exists();
    }
}
