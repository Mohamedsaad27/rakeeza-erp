<?php

namespace App\Modules\Features\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreFeatureRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name_en'        => ['required', 'string', 'max:150'],
            'name_ar'        => ['required', 'string', 'max:150'],
            'code'           => ['required', 'string', 'max:100', 'alpha_dash', Rule::unique('features', 'code')],
            'description_en' => ['nullable', 'string'],
            'description_ar' => ['nullable', 'string'],
            'is_active'      => ['sometimes', 'boolean'],
        ];
    }
}
