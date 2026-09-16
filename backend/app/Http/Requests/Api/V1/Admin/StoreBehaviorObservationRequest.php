<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\BehaviorObservation;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreBehaviorObservationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', BehaviorObservation::class);
    }

    public function rules(): array
    {
        return [
            'student_id' => ['required', Rule::exists('students', 'id')->where('tenant_id', $this->user()->tenant_id)],
            'category' => ['required', Rule::in(['positive', 'discipline', 'participation', 'incident', 'note_generale'])],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'occurred_at' => ['nullable', 'date'],
            'visible_to_parent' => ['sometimes', 'boolean'],
        ];
    }
}
