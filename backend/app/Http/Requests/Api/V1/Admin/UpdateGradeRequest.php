<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateGradeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('grade'));
    }

    public function rules(): array
    {
        return [
            'score' => ['sometimes', 'required', 'numeric', 'min:0'],
            'comment' => ['nullable', 'string', 'max:255'],
        ];
    }
}
