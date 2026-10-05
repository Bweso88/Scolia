<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateTimetableSlotRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('timetable_slot'));
    }

    public function rules(): array
    {
        return [
            'day_of_week' => ['sometimes', 'required', 'integer', 'between:1,7'],
            'start_time' => ['sometimes', 'required', 'date_format:H:i'],
            'end_time' => ['sometimes', 'required', 'date_format:H:i', 'after:start_time'],
            'room' => ['nullable', 'string', 'max:100'],
        ];
    }
}
