<?php

namespace App\Modules\Features\Application\UseCases;

use App\Modules\Features\Application\DTOs\UpdateFeatureDTO;
use App\Modules\Features\Domain\Interfaces\FeatureRepositoryInterface;

class UpdateFeatureUseCase
{
    public function __construct(
        private readonly FeatureRepositoryInterface $repository,
    ) {}

    public function execute(string $featureId, UpdateFeatureDTO $dto): array
    {
        $feature = $this->repository->findById($featureId);
        $feature = $this->repository->update($feature, $dto);
        $locale  = app()->getLocale();

        return [
            'id'             => $feature->feature_id,
            'code'           => $feature->code,
            'name_en'        => $feature->name_en,
            'name_ar'        => $feature->name_ar,
            'label'          => $locale === 'ar' ? $feature->name_ar : $feature->name_en,
            'description_en' => $feature->description_en,
            'description_ar' => $feature->description_ar,
            'is_active'      => $feature->is_active,
        ];
    }
}
