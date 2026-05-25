<?php

namespace App\Modules\Roles\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateRoleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name_en'         => ['sometimes', 'string', 'max:255'],
            'name_ar'         => ['sometimes', 'string', 'max:255'],
            'display_name_en' => ['nullable', 'string', 'max:255'],
            'display_name_ar' => ['nullable', 'string', 'max:255'],
            'description_en'  => ['nullable', 'string', 'max:500'],
            'description_ar'  => ['nullable', 'string', 'max:500'],
            'is_active'       => ['sometimes', 'boolean'],
        ];
    }
}
