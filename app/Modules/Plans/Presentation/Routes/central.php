<?php

use App\Modules\Plans\Presentation\Http\Controllers\PlanController;
use Illuminate\Support\Facades\Route;

Route::get('/', [PlanController::class, 'index']);
Route::post('/', [PlanController::class, 'store']);
Route::get('/{id}', [PlanController::class, 'show']);
Route::put('/{id}', [PlanController::class, 'update']);
Route::delete('/{id}', [PlanController::class, 'destroy']);
Route::put('/{id}/features', [PlanController::class, 'syncFeatures']);
Route::put('/{id}/limits', [PlanController::class, 'syncLimits']);
