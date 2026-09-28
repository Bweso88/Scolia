<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateStudentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('student'));
    }

    public function rules(): array
    {
        return [
            'school_class_id' => [
                'sometimes',
                'required',
                Rule::exists('school_classes', 'id')->where('tenant_id', $this->user()->tenant_id),
            ],
            'first_name' => ['sometimes', 'required', 'string', 'max:255'],
            'last_name' => ['sometimes', 'required', 'string', 'max:255'],
            'birth_date' => ['nullable', 'date'],
            'gender' => ['nullable', Rule::in(['m', 'f'])],
            'enrollment_number' => ['nullable', 'string', 'max:100'],
            'status' => ['sometimes', Rule::in(['active', 'transferred', 'graduated'])],
        ];
    }
}
