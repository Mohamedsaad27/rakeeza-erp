<?php

namespace App\Modules\Roles\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreCustomPermissionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $tenantId = app('tenant_id');

        return [
            'name' => [
                'required', 'string', 'max:150', 'regex:/^[a-z0-9._]+$/',
                Rule::unique('permissions', 'name')->where(fn ($q) => $q->where('tenant_id', $tenantId)),
            ],
            'module'         => ['required', 'string', 'max:100'],
            'label_en'       => ['required', 'string', 'max:255'],
            'label_ar'       => ['required', 'string', 'max:255'],
            'description_en' => ['nullable', 'string', 'max:500'],
            'description_ar' => ['nullable', 'string', 'max:500'],
        ];
    }
}
