<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;

class JustifyAttendanceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('justify', $this->route('attendance_record'));
    }

    public function rules(): array
    {
        return [
            'explanation' => ['required', 'string'],
            'attachment_path' => ['nullable', 'string'],
        ];
    }
}
