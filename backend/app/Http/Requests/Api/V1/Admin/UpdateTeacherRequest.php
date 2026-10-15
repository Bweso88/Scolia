<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateTeacherRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('teacher'));
    }

    public function rules(): array
    {
        $tenantId = $this->user()->tenant_id;

        return [
            'employee_number' => ['nullable', 'string', 'max:255'],
            'assignments' => ['sometimes', 'array'],
            'assignments.*.school_class_id' => ['required', Rule::exists('school_classes', 'id')->where('tenant_id', $tenantId)],
            'assignments.*.subject_id' => ['required', Rule::exists('subjects', 'id')->where('tenant_id', $tenantId)],
        ];
    }
}
