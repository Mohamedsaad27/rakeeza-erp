<?php

namespace App\Modules\Features\Application\UseCases;

use App\Modules\Features\Application\Exceptions\FeatureInUseException;
use App\Modules\Features\Domain\Interfaces\FeatureRepositoryInterface;

class DeleteFeatureUseCase
{
    public function __construct(
        private readonly FeatureRepositoryInterface $repository,
    ) {}

    public function execute(string $featureId): void
    {
        $feature = $this->repository->findById($featureId);

        if ($this->repository->isUsedInPlans($featureId)) {
            throw new FeatureInUseException();
        }

        $this->repository->delete($feature);
    }
}
