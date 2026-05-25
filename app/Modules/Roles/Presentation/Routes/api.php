<?php

use App\Modules\Roles\Presentation\Http\Controllers\PermissionController;
use App\Modules\Roles\Presentation\Http\Controllers\RoleController;
use Illuminate\Support\Facades\Route;

Route::middleware(['permission:role.view'])->get('/', [RoleController::class, 'index']);
Route::middleware(['permission:role.create'])->post('/', [RoleController::class, 'store']);
Route::middleware(['permission:role.view'])->get('/{id}', [RoleController::class, 'show']);
Route::middleware(['permission:role.update'])->put('/{id}', [RoleController::class, 'update']);
Route::middleware(['permission:role.delete'])->delete('/{id}', [RoleController::class, 'destroy']);
Route::middleware(['permission:permission.assign'])->put('/{id}/permissions', [RoleController::class, 'syncPermissions']);
