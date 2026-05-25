<?php

namespace App\Modules\Features\Domain\Interfaces;

use App\Modules\Features\Application\DTOs\CreateFeatureDTO;
use App\Modules\Features\Application\DTOs\UpdateFeatureDTO;
use App\Modules\Features\Infrastructure\Database\Models\Feature;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

interface FeatureRepositoryInterface
{
    public function paginate(int $perPage = 15): LengthAwarePaginator;

    public function allActive(): Collection;

    public function findById(string $featureId): Feature;

    public function findByCode(string $code): ?Feature;

    public function create(CreateFeatureDTO $dto): Feature;

    public function update(Feature $feature, UpdateFeatureDTO $dto): Feature;

    public function delete(Feature $feature): void;

    public function isUsedInPlans(string $featureId): bool;
}
