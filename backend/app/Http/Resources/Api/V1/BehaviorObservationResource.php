<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BehaviorObservationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'student_id' => $this->student_id,
            'category' => $this->category,
            'title' => $this->title,
            'description' => $this->description,
            'occurred_at' => $this->occurred_at?->toIso8601String(),
            'visible_to_parent' => $this->visible_to_parent,
            'author_name' => $this->whenLoaded('author', fn () => $this->author->name),
        ];
    }
}
