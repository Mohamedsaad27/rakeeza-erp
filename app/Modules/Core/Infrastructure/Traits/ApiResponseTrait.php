<?php

namespace App\Modules\Core\Infrastructure\Traits;

use App\Modules\Core\Infrastructure\Helpers\ApiResponse;
use Illuminate\Http\JsonResponse;

trait ApiResponseTrait
{
    protected function success(mixed $data = null, string $message = null, int $statusCode = 200): JsonResponse
    {
        return ApiResponse::success($data, $message, $statusCode);
    }

    protected function error(string $message, mixed $errors = null, int $statusCode = 400): JsonResponse
    {
        return ApiResponse::error($message, $errors, $statusCode);
    }

    protected function paginated(mixed $data, ?string $message = null, int $statusCode = 200): JsonResponse
    {
        return ApiResponse::paginated($data, $message, $statusCode);
    }

    protected function paginatedWithData(mixed $paginatedData, mixed $additionalData, mixed $resourceCollection = null, ?string $message = null, int $statusCode = 200): JsonResponse
    {
        return ApiResponse::paginatedWithData($paginatedData, $additionalData, $resourceCollection, $message, $statusCode);
    }
}

