<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\AttendanceRecord;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreAttendanceRecordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', AttendanceRecord::class);
    }

    public function rules(): array
    {
        return [
            'student_id' => ['required', Rule::exists('students', 'id')->where('tenant_id', $this->user()->tenant_id)],
            'type' => ['required', Rule::in(['absence', 'retard'])],
            'date' => ['required', 'date'],
            'start_time' => ['nullable', 'date_format:H:i'],
            'end_time' => ['nullable', 'date_format:H:i'],
            'reason' => ['nullable', 'string', 'max:255'],
        ];
    }
}
