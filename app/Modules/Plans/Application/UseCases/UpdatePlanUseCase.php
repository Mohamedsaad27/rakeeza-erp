<?php

namespace App\Modules\Plans\Application\UseCases;

use App\Modules\Plans\Application\DTOs\UpdatePlanDTO;
use App\Modules\Plans\Domain\Interfaces\PlanRepositoryInterface;

class UpdatePlanUseCase
{
    public function __construct(
        private readonly PlanRepositoryInterface $repository,
    ) {}

    public function execute(string $planId, UpdatePlanDTO $dto): array
    {
        $plan = $this->repository->findById($planId);
        $plan = $this->repository->update($plan, $dto);

        return CreatePlanUseCase::formatPlan($plan);
    }
}
