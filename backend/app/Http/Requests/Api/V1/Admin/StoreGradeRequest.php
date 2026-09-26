<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\Grade;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreGradeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Grade::class);
    }

    public function rules(): array
    {
        $tenantId = $this->user()->tenant_id;

        return [
            'student_id' => ['required', Rule::exists('students', 'id')->where('tenant_id', $tenantId)],
            'subject_id' => ['required', Rule::exists('subjects', 'id')->where('tenant_id', $tenantId)],
            'grading_period_id' => ['required', Rule::exists('grading_periods', 'id')->where('tenant_id', $tenantId)],
            'score' => ['required', 'numeric', 'min:0'],
            'max_score' => ['nullable', 'numeric', 'min:1'],
            'coefficient' => ['nullable', 'numeric', 'min:0.1'],
            'comment' => ['nullable', 'string', 'max:255'],
        ];
    }
}
