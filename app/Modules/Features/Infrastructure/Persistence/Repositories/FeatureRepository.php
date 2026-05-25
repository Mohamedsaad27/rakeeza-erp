<?php

namespace App\Modules\Features\Infrastructure\Persistence\Repositories;

use App\Modules\Features\Application\DTOs\CreateFeatureDTO;
use App\Modules\Features\Application\DTOs\UpdateFeatureDTO;
use App\Modules\Features\Domain\Interfaces\FeatureRepositoryInterface;
use App\Modules\Features\Infrastructure\Database\Models\Feature;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class FeatureRepository implements FeatureRepositoryInterface
{
    public function paginate(int $perPage = 15): LengthAwarePaginator
    {
        return Feature::query()->orderBy('name_en')->paginate($perPage);
    }

    public function allActive(): Collection
    {
        return Feature::query()->where('is_active', true)->orderBy('name_en')->get();
    }

    public function findById(string $featureId): Feature
    {
        return Feature::query()->where('feature_id', $featureId)->firstOrFail();
    }

    public function findByCode(string $code): ?Feature
    {
        return Feature::query()->where('code', $code)->first();
    }

    public function create(CreateFeatureDTO $dto): Feature
    {
        return Feature::create([
            'name_en'        => $dto->nameEn,
            'name_ar'        => $dto->nameAr,
            'code'           => $dto->code,
            'description_en' => $dto->descriptionEn,
            'description_ar' => $dto->descriptionAr,
            'is_active'      => $dto->isActive,
        ]);
    }

    public function update(Feature $feature, UpdateFeatureDTO $dto): Feature
    {
        $feature->update(array_filter([
            'name_en'        => $dto->nameEn,
            'name_ar'        => $dto->nameAr,
            'description_en' => $dto->descriptionEn,
            'description_ar' => $dto->descriptionAr,
            'is_active'      => $dto->isActive,
        ], fn ($v) => $v !== null));

        return $feature->fresh();
    }

    public function delete(Feature $feature): void
    {
        $feature->delete();
    }

    public function isUsedInPlans(string $featureId): bool
    {
        return DB::table('plan_features')->where('feature_id', $featureId)->exists();
    }
}
