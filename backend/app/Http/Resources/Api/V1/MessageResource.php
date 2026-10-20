<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'body' => $this->body,
            'sender_id' => $this->sender_user_id,
            'sender_name' => $this->whenLoaded('sender', fn () => $this->sender->name),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
