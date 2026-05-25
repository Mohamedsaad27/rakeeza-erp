<?php

use App\Modules\Roles\Presentation\Http\Controllers\PermissionController;
use Illuminate\Support\Facades\Route;

Route::middleware(['permission:permission.view'])->get('/', [PermissionController::class, 'index']);
Route::middleware(['permission:permission.view'])->get('/matrix', [PermissionController::class, 'matrix']);
Route::middleware(['permission:permission.assign'])->post('/', [PermissionController::class, 'store']);
Route::middleware(['permission:permission.assign'])->delete('/{id}', [PermissionController::class, 'destroy']);
