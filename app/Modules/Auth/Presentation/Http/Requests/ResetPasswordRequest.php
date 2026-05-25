<?php

namespace App\Modules\Auth\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ResetPasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tenant_id' => ['required', 'uuid', 'exists:tenants,tenant_id'],
            'email'     => ['required', 'email', 'max:255'],
            'token'     => ['required', 'string'],
            'password'  => ['required', 'string', 'min:8', 'confirmed'],
        ];
    }
}
