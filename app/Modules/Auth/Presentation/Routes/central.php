<?php

use App\Modules\Auth\Presentation\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

Route::post('login', [AuthController::class, 'loginPlatform'])->name('auth.platform.login');

Route::middleware('auth:platform')->group(function () {
    Route::post('logout', [AuthController::class, 'logoutPlatform'])->name('auth.platform.logout');
    Route::post('refresh', [AuthController::class, 'refreshPlatform'])->name('auth.platform.refresh');
    Route::get('me', [AuthController::class, 'mePlatform'])->name('auth.platform.me');
});
