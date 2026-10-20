<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\Student;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreStudentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Student::class);
    }

    public function rules(): array
    {
        return [
            'school_class_id' => [
                'required',
                Rule::exists('school_classes', 'id')->where('tenant_id', $this->user()->tenant_id),
            ],
            'first_name' => ['required', 'string', 'max:255'],
            'last_name' => ['required', 'string', 'max:255'],
            'birth_date' => ['nullable', 'date'],
            'gender' => ['nullable', Rule::in(['m', 'f'])],
            'enrollment_number' => ['nullable', 'string', 'max:100'],
        ];
    }
}
