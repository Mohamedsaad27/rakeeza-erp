<?php

namespace App\Modules\Plans\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StorePlanRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name_en'       => ['required', 'string', 'max:150'],
            'name_ar'       => ['required', 'string', 'max:150'],
            'price'         => ['required', 'numeric', 'min:0'],
            'billing_cycle' => ['required', 'integer', Rule::in([1, 2, 3])],
            'trial_days'    => ['sometimes', 'integer', 'min:0'],
            'max_users'     => ['nullable', 'integer', 'min:1'],
            'max_branches'  => ['nullable', 'integer', 'min:1'],
            'is_active'     => ['sometimes', 'boolean'],
        ];
    }
}
