<?php

namespace App\Modules\Core\Infrastructure\Helpers;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Contracts\Pagination\Paginator;
use Illuminate\Pagination\CursorPaginator;

class PaginationMeta
{
    public static function getMeta(mixed $paginator): array
    {
        // Cursor Pagination
        if ($paginator instanceof CursorPaginator) {
            return [
                'type' => 'cursor',
                'next_page' => $paginator->nextCursor()?->encode(),
                'prev_page' => $paginator->previousCursor()?->encode(),
                'per_page' => $paginator->perPage(),
                'has_more' => $paginator->hasMorePages(),
            ];
        }

        // LengthAware Pagination (BEST for APIs)
        if ($paginator instanceof LengthAwarePaginator) {
            return [
                'type' => 'length_aware',
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'from' => $paginator->firstItem(),
                'to' => $paginator->lastItem(),
                'has_more' => $paginator->hasMorePages(),
            ];
        }

        // Simple Paginator
        if ($paginator instanceof Paginator) {
            return [
                'type' => 'simple',
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'has_more' => $paginator->hasMorePages(),
            ];
        }

        return [];
    }
}