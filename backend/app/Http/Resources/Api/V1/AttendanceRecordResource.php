<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AttendanceRecordResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $justification = $this->justification;

        return [
            'id' => $this->id,
            'student_id' => $this->student_id,
            'type' => $this->type,
            'date' => $this->date?->toDateString(),
            'start_time' => $this->start_time,
            'end_time' => $this->end_time,
            'reason' => $this->reason,
            'justification' => $justification ? [
                'id' => $justification->id,
                'explanation' => $justification->explanation,
                'status' => $justification->status,
            ] : null,
        ];
    }
}
