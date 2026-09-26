<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\Document;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreDocumentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Document::class);
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'category' => ['required', Rule::in(['bulletin', 'circulaire', 'reglement', 'calendrier', 'autre'])],
            'visible_to' => ['required', Rule::in(['all', 'school_class', 'student', 'user'])],
            'target_id' => ['required_unless:visible_to,all', 'nullable', 'integer'],
            'file' => ['required', 'file', 'mimes:pdf,jpg,jpeg,png,doc,docx', 'max:10240'],
        ];
    }
}
