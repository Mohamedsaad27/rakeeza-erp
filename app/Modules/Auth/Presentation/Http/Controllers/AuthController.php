<?php

namespace App\Modules\Auth\Presentation\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Application\DTOs\ForgotPasswordDTO;
use App\Modules\Auth\Application\DTOs\LoginDTO;
use App\Modules\Auth\Application\DTOs\RegisterDTO;
use App\Modules\Auth\Application\DTOs\ResetPasswordDTO;
use App\Modules\Auth\Application\UseCases\ForgotPasswordUseCase;
use App\Modules\Auth\Application\UseCases\LoginUseCase;
use App\Modules\Auth\Application\UseCases\LogoutUseCase;
use App\Modules\Auth\Application\UseCases\RefreshTokenUseCase;
use App\Modules\Auth\Application\UseCases\RegisterUseCase;
use App\Modules\Auth\Application\UseCases\ResetPasswordUseCase;
use App\Modules\Auth\Presentation\Http\Requests\ForgotPasswordRequest;
use App\Modules\Auth\Presentation\Http\Requests\LoginRequest;
use App\Modules\Auth\Presentation\Http\Requests\PlatformLoginRequest;
use App\Modules\Auth\Presentation\Http\Requests\RegisterRequest;
use App\Modules\Auth\Presentation\Http\Requests\ResetPasswordRequest;
use App\Modules\Auth\Presentation\Resources\AuthUserResource;
use App\Modules\Core\Infrastructure\Helpers\ApiResponse;
use Illuminate\Http\JsonResponse;

class AuthController extends Controller
{
    public function __construct(
        private readonly LoginUseCase $loginUseCase,
        private readonly RegisterUseCase $registerUseCase,
        private readonly LogoutUseCase $logoutUseCase,
        private readonly RefreshTokenUseCase $refreshTokenUseCase,
        private readonly ForgotPasswordUseCase $forgotPasswordUseCase,
        private readonly ResetPasswordUseCase $resetPasswordUseCase,
    ) {}

    public function loginTenant(LoginRequest $request): JsonResponse
    {
        $data = $this->loginUseCase->execute(new LoginDTO(
            login: $request->validated('login'),
            password: $request->validated('password'),
            guard: 'api',
            tenantId: $request->validated('tenant_id'),
        ));

        return ApiResponse::success($data, __('auth.login_success'));
    }

    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $data = $this->registerUseCase->execute(new RegisterDTO(
            tenantId: $validated['tenant_id'],
            name: $validated['name'],
            username: $validated['username'],
            email: $validated['email'],
            password: $validated['password'],
            phone: $validated['phone'] ?? null,
        ));

        return ApiResponse::success($data, __('auth.register_success'), 201);
    }

    public function logoutTenant(): JsonResponse
    {
        $this->logoutUseCase->execute('api');

        return ApiResponse::success(null, __('auth.logout_success'));
    }

    public function refreshTenant(): JsonResponse
    {
        $data = $this->refreshTokenUseCase->execute('api');

        return ApiResponse::success($data, __('auth.token_refreshed'));
    }

    public function meTenant(): JsonResponse
    {
        return ApiResponse::success(
            new AuthUserResource(auth('api')->user()),
            __('auth.profile_retrieved'),
        );
    }

    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $this->forgotPasswordUseCase->execute(new ForgotPasswordDTO(
            email: $request->validated('email'),
            tenantId: $request->validated('tenant_id'),
        ));

        return ApiResponse::success(null, __('auth.reset_link_sent'));
    }

    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $this->resetPasswordUseCase->execute(new ResetPasswordDTO(
            token: $validated['token'],
            email: $validated['email'],
            password: $validated['password'],
            tenantId: $validated['tenant_id'],
        ));

        return ApiResponse::success(null, __('auth.password_reset_success'));
    }

    public function loginPlatform(PlatformLoginRequest $request): JsonResponse
    {
        $data = $this->loginUseCase->execute(new LoginDTO(
            login: $request->validated('login'),
            password: $request->validated('password'),
            guard: 'platform',
        ));

        return ApiResponse::success($data, __('auth.login_success'));
    }

    public function logoutPlatform(): JsonResponse
    {
        $this->logoutUseCase->execute('platform');

        return ApiResponse::success(null, __('auth.logout_success'));
    }

    public function refreshPlatform(): JsonResponse
    {
        $data = $this->refreshTokenUseCase->execute('platform');

        return ApiResponse::success($data, __('auth.token_refreshed'));
    }

    public function mePlatform(): JsonResponse
    {
        return ApiResponse::success(
            new AuthUserResource(auth('platform')->user()),
            __('auth.profile_retrieved'),
        );
    }
}
