<?php

namespace App\Modules\Plans\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SyncPlanLimitsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'limits'         => ['required', 'array'],
            'limits.*.key'   => ['required', 'string', 'max:100'],
            'limits.*.value' => ['required', 'integer', 'min:0'],
        ];
    }
}
