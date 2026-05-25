<?php

namespace App\Modules\Plans\Application\UseCases;

use App\Modules\Plans\Application\Exceptions\PlanInUseException;
use App\Modules\Plans\Domain\Interfaces\PlanRepositoryInterface;

class DeletePlanUseCase
{
    public function __construct(
        private readonly PlanRepositoryInterface $repository,
    ) {}

    public function execute(string $planId): void
    {
        $plan = $this->repository->findById($planId);

        if ($this->repository->isUsedByTenants($planId)) {
            throw new PlanInUseException();
        }

        $this->repository->delete($plan);
    }
}
