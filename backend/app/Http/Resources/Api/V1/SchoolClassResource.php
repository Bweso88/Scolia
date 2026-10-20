<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SchoolClassResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'level' => $this->level,
            'school_year' => $this->whenLoaded('schoolYear', fn () => [
                'id' => $this->schoolYear->id,
                'label' => $this->schoolYear->label,
            ]),
            'homeroom_teacher' => $this->whenLoaded('homeroomTeacher', fn () => $this->homeroomTeacher ? [
                'id' => $this->homeroomTeacher->id,
                'name' => $this->homeroomTeacher->user->name,
            ] : null),
            'students_count' => $this->whenCounted('students'),
        ];
    }
}
