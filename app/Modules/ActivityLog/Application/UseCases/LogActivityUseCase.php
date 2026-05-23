<?php

namespace App\Modules\ActivityLog\Application\UseCases;

use App\Modules\ActivityLog\Application\DTOs\LogActivityDTO;
use App\Modules\ActivityLog\Domain\Interfaces\ActivityLogRepositoryInterface;

class LogActivityUseCase
{
    public function __construct(
        private readonly ActivityLogRepositoryInterface $repository,
    ) {}

    public function execute(LogActivityDTO $dto): void
    {
        dispatch(fn () => $this->repository->logTenantActivity($dto))
            ->afterResponse();
    }
}
