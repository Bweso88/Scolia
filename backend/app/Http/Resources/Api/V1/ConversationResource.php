<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConversationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'subject' => $this->subject,
            'participants' => $this->whenLoaded('participants', fn () => $this->participants->map(fn ($p) => [
                'id' => $p->id,
                'name' => $p->name,
            ])),
            // Élève concerné par cette conversation (fil parent ↔ enseignant),
            // absent pour un fil général avec la direction.
            'student' => $this->whenLoaded('student', fn () => $this->student ? [
                'id' => $this->student->id,
                'first_name' => $this->student->first_name,
                'last_name' => $this->student->last_name,
                'school_class' => $this->student->relationLoaded('schoolClass') && $this->student->schoolClass
                    ? ['id' => $this->student->schoolClass->id, 'name' => $this->student->schoolClass->name]
                    : null,
            ] : null),
            'last_message' => $this->whenLoaded('messages', fn () => optional($this->messages->last())->body),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
