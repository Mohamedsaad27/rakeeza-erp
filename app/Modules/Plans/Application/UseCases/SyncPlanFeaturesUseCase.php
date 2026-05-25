<?php

namespace App\Modules\Plans\Application\UseCases;

use App\Modules\Features\Domain\Interfaces\FeatureRepositoryInterface;
use App\Modules\Plans\Application\DTOs\SyncPlanFeaturesDTO;
use App\Modules\Plans\Domain\Interfaces\PlanRepositoryInterface;

class SyncPlanFeaturesUseCase
{
    public function __construct(
        private readonly PlanRepositoryInterface $planRepository,
        private readonly FeatureRepositoryInterface $featureRepository,
    ) {}

    public function execute(SyncPlanFeaturesDTO $dto): array
    {
        $plan = $this->planRepository->findById($dto->planId);

        $sync = [];
        foreach ($dto->features as $item) {
            $featureId = $item['feature_id'] ?? $item['id'] ?? null;
            if (! $featureId) {
                continue;
            }
            $this->featureRepository->findById($featureId);
            $sync[$featureId] = $item['enabled'] ?? true;
        }

        $this->planRepository->syncFeatures($plan, $sync);

        return ['features_count' => count($sync)];
    }
}
