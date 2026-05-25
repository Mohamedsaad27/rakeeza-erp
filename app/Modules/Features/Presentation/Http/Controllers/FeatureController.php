<?php

namespace App\Modules\Features\Presentation\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Core\Infrastructure\Helpers\ApiResponse;
use App\Modules\Core\Infrastructure\Helpers\PaginationMeta;
use App\Modules\Features\Application\DTOs\CreateFeatureDTO;
use App\Modules\Features\Application\DTOs\UpdateFeatureDTO;
use App\Modules\Features\Application\UseCases\CreateFeatureUseCase;
use App\Modules\Features\Application\UseCases\DeleteFeatureUseCase;
use App\Modules\Features\Application\UseCases\GetFeatureUseCase;
use App\Modules\Features\Application\UseCases\GetFeaturesUseCase;
use App\Modules\Features\Application\UseCases\UpdateFeatureUseCase;
use App\Modules\Features\Presentation\Http\Requests\StoreFeatureRequest;
use App\Modules\Features\Presentation\Http\Requests\UpdateFeatureRequest;
use App\Modules\Features\Presentation\Resources\FeatureResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FeatureController extends Controller
{
    public function __construct(
        private readonly GetFeaturesUseCase $getFeaturesUseCase,
        private readonly GetFeatureUseCase $getFeatureUseCase,
        private readonly CreateFeatureUseCase $createFeatureUseCase,
        private readonly UpdateFeatureUseCase $updateFeatureUseCase,
        private readonly DeleteFeatureUseCase $deleteFeatureUseCase,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $features = $this->getFeaturesUseCase->execute((int) $request->input('per_page', 15));

        return response()->json([
            'isSuccess' => true,
            'message'   => __('features.list_retrieved'),
            'data'      => FeatureResource::collection($features->items()),
            'meta'      => PaginationMeta::getMeta($features),
        ]);
    }

    public function store(StoreFeatureRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $data = $this->createFeatureUseCase->execute(new CreateFeatureDTO(
            nameEn: $validated['name_en'],
            nameAr: $validated['name_ar'],
            code: $validated['code'],
            descriptionEn: $validated['description_en'] ?? null,
            descriptionAr: $validated['description_ar'] ?? null,
            isActive: $validated['is_active'] ?? true,
        ));

        return ApiResponse::success($data, __('features.feature_created'), 201);
    }

    public function show(string $id): JsonResponse
    {
        $data = $this->getFeatureUseCase->execute($id);

        return ApiResponse::success($data, __('features.feature_retrieved'));
    }

    public function update(UpdateFeatureRequest $request, string $id): JsonResponse
    {
        $validated = $request->validated();

        $data = $this->updateFeatureUseCase->execute($id, new UpdateFeatureDTO(
            nameEn: $validated['name_en'] ?? null,
            nameAr: $validated['name_ar'] ?? null,
            descriptionEn: $validated['description_en'] ?? null,
            descriptionAr: $validated['description_ar'] ?? null,
            isActive: $validated['is_active'] ?? null,
        ));

        return ApiResponse::success($data, __('features.feature_updated'));
    }

    public function destroy(string $id): JsonResponse
    {
        $this->deleteFeatureUseCase->execute($id);

        return ApiResponse::success(null, __('features.feature_deleted'));
    }
}
