<?php

namespace App\Modules\Roles\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreRoleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $tenantId = app('tenant_id');

        return [
            'name'            => [
                'required', 'string', 'max:150', 'alpha_dash',
                Rule::unique('roles', 'name')->where(fn ($q) => $q->where('tenant_id', $tenantId)),
            ],
            'name_en'         => ['required', 'string', 'max:255'],
            'name_ar'         => ['required', 'string', 'max:255'],
            'display_name_en' => ['nullable', 'string', 'max:255'],
            'display_name_ar' => ['nullable', 'string', 'max:255'],
            'description_en'  => ['nullable', 'string', 'max:500'],
            'description_ar'  => ['nullable', 'string', 'max:500'],
        ];
    }
}
