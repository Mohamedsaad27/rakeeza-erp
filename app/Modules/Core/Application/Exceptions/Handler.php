<?php

namespace App\Modules\Core\Application\Exceptions;

use App\Modules\Core\Application\Exceptions\BaseException;
use App\Modules\Core\Application\Exceptions\PlanLimitException;
use App\Modules\Core\Infrastructure\Helpers\ApiResponse;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException;
use Symfony\Component\HttpKernel\Exception\UnauthorizedHttpException;
use InvalidArgumentException;
use Throwable;

class Handler extends ExceptionHandler
{
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    public function register(): void
    {
        $this->reportable(function (Throwable $e) {
            //
        });
    }

    public function render($request, Throwable $e)
    {
        if ($request->is('api/*') || $request->expectsJson()) {
            return $this->handleApiException($request, $e);
        }

        return parent::render($request, $e);
    }

    protected function unauthenticated($request, AuthenticationException $exception)
    {
        if ($request->is('api/*') || $request->expectsJson()) {
            return ApiResponse::error(
                __('messages.unauthenticated'),
                null,
                401
            );
        }

        return redirect()->guest(route('login'));
    }

    public function handleApiException($request, Throwable $e)
    {
        if ($e instanceof ValidationException) {
            return ApiResponse::error(
                __('messages.validation_failed'),
                $e->errors(),
                422
            );
        }

        if ($e instanceof AuthenticationException) {
            return ApiResponse::error(
                __('messages.unauthenticated'),
                null,
                401
            );
        }

        if ($e instanceof UnauthorizedHttpException) {
            return ApiResponse::error(
                $e->getMessage() ?: __('messages.token_not_provided'),
                null,
                401
            );
        }
        if ($e instanceof PlanLimitException) {
            return ApiResponse::error(
                $e->getMessage(),
                ['limit_key' => $e->getLimitKey(), 'current' => $e->getCurrent(), 'allowed' => $e->getAllowed()],
                $e->getStatusCode()
            );
        }

        if ($e instanceof BaseException) {
            return ApiResponse::error(
                $e->getMessage(),
                null,
                $e->getStatusCode()
            );
        }

        if ($e instanceof ModelNotFoundException) {
            return ApiResponse::error(
                __('messages.resource_not_found'),
                null,
                404
            );
        }

        if ($e instanceof NotFoundHttpException) {
            return ApiResponse::error(
                __('messages.page_not_found'),
                ['detail' => __('messages.page_unavailable')],
                404
            );
        }

        if ($e instanceof MethodNotAllowedHttpException) {
            return ApiResponse::error(
                __('messages.method_not_allowed'),
                null,
                405
            );
        }

        if ($e instanceof InvalidArgumentException) {
            return ApiResponse::error(
                $e->getMessage(),
                null,
                500
            );
        }

        if (config('app.debug')) {
            return ApiResponse::error(
                $e->getMessage(),
                [
                    'exception' => get_class($e),
                    'file' => $e->getFile(),
                    'line' => $e->getLine(),
                    'trace' => $e->getTraceAsString(),
                ],
                500
            );
        }

        return ApiResponse::error(
            __('messages.something_went_wrong'),
            null,
            500
        );
    }
}
