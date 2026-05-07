<?php

namespace App\Modules\Core\Infrastructure\Helpers;

use Illuminate\Http\JsonResponse;

class ApiResponse
{
    public static function success(mixed $data = null, string $message = null, int $statusCode = 200): JsonResponse
    {
        return response()->json([
            'isSuccess' => true,
            'message' => $message ?? __('messages.success'),
            'data' => $data,
        ], $statusCode);
    }

    public static function error(string $message, mixed $errors = null, int $statusCode = 400): JsonResponse
    {
        return response()->json([
            'isSuccess' => false,
            'message' => $message,
            'errors' => $errors,
        ], $statusCode);
    }

    public static function paginated(mixed $data, ?string $message = null, int $statusCode = 200): JsonResponse
    {
        return response()->json([
            'isSuccess' => true,
            'message' => $message ?? __('messages.success'),
            'data' => PaginationMeta::getMeta($data),
        ], $statusCode);
    }

    public static function paginatedWithData(mixed $paginatedData, mixed $additionalData, mixed $resourceCollection = null, ?string $message = null, int $statusCode = 200): JsonResponse
    {
        $data = array_merge($additionalData, PaginationMeta::getMeta($paginatedData));

        return response()->json([
            'isSuccess' => true,
            'message' => $message ?? __('messages.success'),
            'data' => $data,
        ], $statusCode);
    }
}

