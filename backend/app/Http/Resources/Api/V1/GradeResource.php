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
            'student_id' => $this->student_id,
            'student_name' => $this->whenLoaded('student', fn () => trim($this->student->first_name.' '.$this->student->last_name)),
            'subject' => $this->whenLoaded('subject', fn () => $this->subject->name),
            'homework_id' => $this->homework_id,
            'homework_title' => $this->whenLoaded('homework', fn () => $this->homework?->title),
            'grading_period' => $this->whenLoaded('gradingPeriod', fn () => $this->gradingPeriod->label),
            'type' => $this->type,
            'score' => (float) $this->score,
            'max_score' => (float) $this->max_score,
            'coefficient' => (float) $this->coefficient,
            'comment' => $this->comment,
        ];
    }
}
