<?php

namespace App\Modules\Plans\Application\UseCases;

use App\Modules\Plans\Application\DTOs\SyncPlanLimitsDTO;
use App\Modules\Plans\Domain\Interfaces\PlanRepositoryInterface;

class SyncPlanLimitsUseCase
{
    public function __construct(
        private readonly PlanRepositoryInterface $repository,
    ) {}

    public function execute(SyncPlanLimitsDTO $dto): array
    {
        $plan = $this->repository->findById($dto->planId);
        $this->repository->syncLimits($plan, $dto->limits);

        return ['limits_count' => count($dto->limits)];
    }
}
