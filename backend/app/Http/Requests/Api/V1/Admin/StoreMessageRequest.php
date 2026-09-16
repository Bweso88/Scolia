<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\Message;
use Illuminate\Foundation\Http\FormRequest;

class StoreMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', [Message::class, $this->route('conversation')]);
    }

    public function rules(): array
    {
        return [
            'body' => ['required', 'string'],
        ];
    }
}
