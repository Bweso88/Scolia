<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\Teacher;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Crée soit un professeur pour un compte utilisateur existant
 * (`user_id`), soit le compte et le professeur d'un coup (`name` +
 * `email` + `password`) — jamais les deux à la fois.
 */
class StoreTeacherRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Teacher::class);
    }

    public function rules(): array
    {
        $tenantId = $this->user()->tenant_id;

        return [
            'user_id' => [
                'required_without_all:name,email,password',
                Rule::exists('users', 'id')->where('tenant_id', $tenantId),
            ],
            'name' => ['required_without:user_id', 'string', 'max:255'],
            'email' => ['required_without:user_id', 'email', Rule::unique('users', 'email')->where('tenant_id', $tenantId)],
            'password' => ['required_without:user_id', 'string', 'min:8'],
            'employee_number' => ['nullable', 'string', 'max:255'],
            'assignments' => ['sometimes', 'array'],
            'assignments.*.school_class_id' => ['required', Rule::exists('school_classes', 'id')->where('tenant_id', $tenantId)],
            'assignments.*.subject_id' => ['required', Rule::exists('subjects', 'id')->where('tenant_id', $tenantId)],
        ];
    }
}
