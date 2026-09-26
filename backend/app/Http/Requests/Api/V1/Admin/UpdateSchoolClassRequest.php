<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateSchoolClassRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('school_class'));
    }

    public function rules(): array
    {
        $tenantId = $this->user()->tenant_id;

        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'level' => ['nullable', 'string', 'max:255'],
            'school_year_id' => ['sometimes', 'required', Rule::exists('school_years', 'id')->where('tenant_id', $tenantId)],
            'homeroom_teacher_id' => ['nullable', Rule::exists('teachers', 'id')->where('tenant_id', $tenantId)],
        ];
    }
}
