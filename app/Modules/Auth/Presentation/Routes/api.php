<?php

use App\Modules\Auth\Presentation\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

Route::post('login', [AuthController::class, 'loginTenant'])->name('auth.tenant.login');
Route::post('register', [AuthController::class, 'register'])->name('auth.tenant.register');
Route::post('forgot-password', [AuthController::class, 'forgotPassword'])->name('auth.tenant.forgot-password');
Route::post('reset-password', [AuthController::class, 'resetPassword'])->name('auth.tenant.reset-password');

Route::middleware('auth:api')->group(function () {
    Route::post('logout', [AuthController::class, 'logoutTenant'])->name('auth.tenant.logout');
    Route::post('refresh', [AuthController::class, 'refreshTenant'])->name('auth.tenant.refresh');
    Route::get('me', [AuthController::class, 'meTenant'])->name('auth.tenant.me');
});
