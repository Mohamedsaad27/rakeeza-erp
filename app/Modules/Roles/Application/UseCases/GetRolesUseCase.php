<?php

namespace App\Modules\Roles\Application\UseCases;

use App\Modules\Roles\Domain\Interfaces\RoleRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class GetRolesUseCase
{
    public function __construct(
        private readonly RoleRepositoryInterface $repository,
    ) {}

    public function execute(string $tenantId, int $perPage = 15): LengthAwarePaginator
    {
        return $this->repository->paginate($tenantId, $perPage);
    }
}
