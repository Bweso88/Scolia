<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HomeworkResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'instructions' => $this->instructions,
            'due_date' => $this->due_date?->toDateString(),
            'published_at' => $this->published_at?->toIso8601String(),
            'subject' => $this->whenLoaded('subject', fn () => ['id' => $this->subject->id, 'name' => $this->subject->name]),
            'school_class' => $this->whenLoaded('schoolClass', fn () => ['id' => $this->schoolClass->id, 'name' => $this->schoolClass->name]),
            'teacher_name' => $this->whenLoaded('teacher', fn () => $this->teacher?->user?->name),
            'status' => $this->whenLoaded('statuses', fn () => $this->statuses->first()?->status ?? 'pending', 'pending'),
            'attachments' => $this->whenLoaded('attachments', fn () => $this->attachments->map(fn ($a) => [
                'id' => $a->id,
                'file_name' => $a->file_name,
                'size_bytes' => $a->size_bytes,
                'url' => asset('storage/'.$a->file_path),
            ])),
        ];
    }
}
