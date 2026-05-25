<?php

namespace App\Modules\Plans\Application\UseCases;

use App\Modules\Plans\Domain\Interfaces\PlanRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class GetPlansUseCase
{
    public function __construct(
        private readonly PlanRepositoryInterface $repository,
    ) {}

    public function execute(int $perPage = 15): LengthAwarePaginator
    {
        return $this->repository->paginate($perPage);
    }
}
