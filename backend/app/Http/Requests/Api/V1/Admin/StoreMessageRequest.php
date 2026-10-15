<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Models\Message;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

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

    /**
     * Même heure limite que pour l'ouverture d'une conversation
     * (StoreConversationRequest) : ne s'applique qu'aux parents, jamais
     * au personnel qui doit pouvoir répondre à tout moment.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            if (! $this->user()->hasRole('parent')) {
                return;
            }

            if ($this->user()->tenant?->settings?->isPastMessagingCutoff()) {
                $validator->errors()->add(
                    'body',
                    "La messagerie est fermée pour aujourd'hui (heure limite : {$this->user()->tenant->settings->messaging_cutoff_time}). Réessayez demain."
                );
            }
        });
    }
}
