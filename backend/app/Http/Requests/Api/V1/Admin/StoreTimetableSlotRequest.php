<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\TimetableSlot;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreTimetableSlotRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', TimetableSlot::class);
    }

    public function rules(): array
    {
        $tenantId = $this->user()->tenant_id;

        return [
            'school_class_id' => ['required', Rule::exists('school_classes', 'id')->where('tenant_id', $tenantId)],
            'subject_id' => ['required', Rule::exists('subjects', 'id')->where('tenant_id', $tenantId)],
            'teacher_id' => ['required', Rule::exists('teachers', 'id')->where('tenant_id', $tenantId)],
            'day_of_week' => ['required', 'integer', 'between:1,7'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i', 'after:start_time'],
            'room' => ['nullable', 'string', 'max:100'],
        ];
    }
}
