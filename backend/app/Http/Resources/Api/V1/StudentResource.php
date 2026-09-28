<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StudentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'birth_date' => $this->birth_date?->toDateString(),
            'gender' => $this->gender,
            'enrollment_number' => $this->enrollment_number,
            'status' => $this->status,
            'is_activated' => $this->isActivated(),
            'school_class' => [
                'id' => $this->schoolClass->id,
                'name' => $this->schoolClass->name,
            ],
        ];
    }
}
