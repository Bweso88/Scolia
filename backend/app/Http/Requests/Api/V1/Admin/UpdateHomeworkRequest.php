<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateHomeworkRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('homework'));
    }

    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'instructions' => ['nullable', 'string'],
            'due_date' => ['sometimes', 'required', 'date'],
        ];
    }
}
