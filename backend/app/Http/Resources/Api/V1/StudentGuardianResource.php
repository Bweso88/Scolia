<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StudentGuardianResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'name' => $this->whenLoaded('guardianUser', fn () => $this->guardianUser->name),
            'email' => $this->whenLoaded('guardianUser', fn () => $this->guardianUser->email),
            'relationship_type' => $this->relationship_type,
            'is_primary_contact' => $this->is_primary_contact,
        ];
    }
}
