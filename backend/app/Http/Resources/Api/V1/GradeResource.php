<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GradeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'subject' => $this->whenLoaded('subject', fn () => $this->subject->name),
            'grading_period' => $this->whenLoaded('gradingPeriod', fn () => $this->gradingPeriod->label),
            'score' => (float) $this->score,
            'max_score' => (float) $this->max_score,
            'coefficient' => (float) $this->coefficient,
            'comment' => $this->comment,
        ];
    }
}
