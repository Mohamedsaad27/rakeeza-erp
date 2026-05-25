<?php

namespace App\Modules\Plans\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SyncPlanFeaturesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'features'            => ['required', 'array'],
            'features.*.feature_id' => ['required', 'uuid'],
            'features.*.enabled'    => ['sometimes', 'boolean'],
        ];
    }
}
