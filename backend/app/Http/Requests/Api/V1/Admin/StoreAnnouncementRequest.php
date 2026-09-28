<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\Announcement;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreAnnouncementRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Announcement::class);
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'body' => ['required', 'string'],
            'category' => ['required', Rule::in(['info', 'reunion', 'sortie', 'examen', 'vacances', 'urgence'])],
            'targets' => ['required', 'array', 'min:1'],
            'targets.*.target_type' => ['required', Rule::in(['all', 'school_class', 'user'])],
            'targets.*.target_id' => ['required_unless:targets.*.target_type,all', 'nullable', 'integer'],
        ];
    }
}
