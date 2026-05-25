<?php

namespace App\Modules\Features\Application\UseCases;

use App\Modules\Features\Domain\Interfaces\FeatureRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class GetFeaturesUseCase
{
    public function __construct(
        private readonly FeatureRepositoryInterface $repository,
    ) {}

    public function execute(int $perPage = 15): LengthAwarePaginator
    {
        return $this->repository->paginate($perPage);
    }
}
