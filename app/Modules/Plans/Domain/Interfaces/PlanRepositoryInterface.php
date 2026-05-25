<?php

namespace App\Modules\Plans\Domain\Interfaces;

use App\Modules\Plans\Application\DTOs\CreatePlanDTO;
use App\Modules\Plans\Application\DTOs\UpdatePlanDTO;
use App\Modules\Plans\Infrastructure\Database\Models\Plan;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface PlanRepositoryInterface
{
    public function paginate(int $perPage = 15): LengthAwarePaginator;

    public function findById(string $planId): Plan;

    public function getWithRelations(string $planId): Plan;

    public function create(CreatePlanDTO $dto): Plan;

    public function update(Plan $plan, UpdatePlanDTO $dto): Plan;

    public function delete(Plan $plan): void;

    public function syncFeatures(Plan $plan, array $featureSync): void;

    public function syncLimits(Plan $plan, array $limits): void;

    public function isUsedByTenants(string $planId): bool;
}
