<?php

namespace App\Modules\Core\Presentation\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ScopeTenant
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = auth('api')->user();

        if (! $user || empty($user->tenant_id)) {
            return response()->json([
                'status'  => false,
                'message' => __('messages.tenant_not_resolved'),
            ], 401);
        }

        app()->instance('tenant_id', $user->tenant_id);

        return $next($request);
    }
}
