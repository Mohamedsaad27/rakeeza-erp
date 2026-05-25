<?php

namespace App\Modules\Plans\Presentation\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Core\Infrastructure\Helpers\ApiResponse;
use App\Modules\Core\Infrastructure\Helpers\PaginationMeta;
use App\Modules\Plans\Application\DTOs\CreatePlanDTO;
use App\Modules\Plans\Application\DTOs\SyncPlanFeaturesDTO;
use App\Modules\Plans\Application\DTOs\SyncPlanLimitsDTO;
use App\Modules\Plans\Application\DTOs\UpdatePlanDTO;
use App\Modules\Plans\Application\UseCases\CreatePlanUseCase;
use App\Modules\Plans\Application\UseCases\DeletePlanUseCase;
use App\Modules\Plans\Application\UseCases\GetPlanUseCase;
use App\Modules\Plans\Application\UseCases\GetPlansUseCase;
use App\Modules\Plans\Application\UseCases\SyncPlanFeaturesUseCase;
use App\Modules\Plans\Application\UseCases\SyncPlanLimitsUseCase;
use App\Modules\Plans\Application\UseCases\UpdatePlanUseCase;
use App\Modules\Plans\Presentation\Http\Requests\StorePlanRequest;
use App\Modules\Plans\Presentation\Http\Requests\SyncPlanFeaturesRequest;
use App\Modules\Plans\Presentation\Http\Requests\SyncPlanLimitsRequest;
use App\Modules\Plans\Presentation\Http\Requests\UpdatePlanRequest;
use App\Modules\Plans\Presentation\Resources\PlanResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlanController extends Controller
{
    public function __construct(
        private readonly GetPlansUseCase $getPlansUseCase,
        private readonly GetPlanUseCase $getPlanUseCase,
        private readonly CreatePlanUseCase $createPlanUseCase,
        private readonly UpdatePlanUseCase $updatePlanUseCase,
        private readonly DeletePlanUseCase $deletePlanUseCase,
        private readonly SyncPlanFeaturesUseCase $syncPlanFeaturesUseCase,
        private readonly SyncPlanLimitsUseCase $syncPlanLimitsUseCase,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $plans = $this->getPlansUseCase->execute((int) $request->input('per_page', 15));

        return response()->json([
            'isSuccess' => true,
            'message'   => __('plans.list_retrieved'),
            'data'      => PlanResource::collection($plans->items()),
            'meta'      => PaginationMeta::getMeta($plans),
        ]);
    }

    public function store(StorePlanRequest $request): JsonResponse
    {
        $v = $request->validated();

        $data = $this->createPlanUseCase->execute(new CreatePlanDTO(
            nameEn: $v['name_en'],
            nameAr: $v['name_ar'],
            price: (float) $v['price'],
            billingCycle: (int) $v['billing_cycle'],
            trialDays: $v['trial_days'] ?? 0,
            maxUsers: $v['max_users'] ?? null,
            maxBranches: $v['max_branches'] ?? null,
            isActive: $v['is_active'] ?? true,
        ));

        return ApiResponse::success($data, __('plans.plan_created'), 201);
    }

    public function show(string $id): JsonResponse
    {
        return ApiResponse::success(
            $this->getPlanUseCase->execute($id),
            __('plans.plan_retrieved'),
        );
    }

    public function update(UpdatePlanRequest $request, string $id): JsonResponse
    {
        $v = $request->validated();

        $data = $this->updatePlanUseCase->execute($id, new UpdatePlanDTO(
            nameEn: $v['name_en'] ?? null,
            nameAr: $v['name_ar'] ?? null,
            price: isset($v['price']) ? (float) $v['price'] : null,
            billingCycle: isset($v['billing_cycle']) ? (int) $v['billing_cycle'] : null,
            trialDays: $v['trial_days'] ?? null,
            maxUsers: $v['max_users'] ?? null,
            maxBranches: $v['max_branches'] ?? null,
            isActive: $v['is_active'] ?? null,
        ));

        return ApiResponse::success($data, __('plans.plan_updated'));
    }

    public function destroy(string $id): JsonResponse
    {
        $this->deletePlanUseCase->execute($id);

        return ApiResponse::success(null, __('plans.plan_deleted'));
    }

    public function syncFeatures(SyncPlanFeaturesRequest $request, string $id): JsonResponse
    {
        $data = $this->syncPlanFeaturesUseCase->execute(new SyncPlanFeaturesDTO(
            planId: $id,
            features: $request->validated('features'),
        ));

        return ApiResponse::success($data, __('plans.features_synced'));
    }

    public function syncLimits(SyncPlanLimitsRequest $request, string $id): JsonResponse
    {
        $limits = collect($request->validated('limits'))
            ->pluck('value', 'key')
            ->all();

        $data = $this->syncPlanLimitsUseCase->execute(new SyncPlanLimitsDTO(
            planId: $id,
            limits: $limits,
        ));

        return ApiResponse::success($data, __('plans.limits_synced'));
    }
}
