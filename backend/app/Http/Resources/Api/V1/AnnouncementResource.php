<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AnnouncementResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'body' => $this->body,
            'category' => $this->category,
            'published_at' => $this->published_at?->toIso8601String(),
            'author_name' => $this->whenLoaded('author', fn () => $this->author->name),
        ];
    }
}
