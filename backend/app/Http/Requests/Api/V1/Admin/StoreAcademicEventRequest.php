<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\AcademicEvent;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreAcademicEventRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', AcademicEvent::class);
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'start_date' => ['required', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'category' => ['required', Rule::in(['vacances', 'examen', 'evenement', 'reunion', 'autre'])],
        ];
    }
}
