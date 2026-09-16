<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\JustifyAttendanceRequest;
use App\Http\Requests\Api\V1\Admin\ReviewAttendanceJustificationRequest;
use App\Http\Requests\Api\V1\Admin\StoreAttendanceRecordRequest;
use App\Http\Resources\Api\V1\AttendanceRecordResource;
use App\Models\AttendanceRecord;
use Illuminate\Http\Request;

class AttendanceRecordController extends Controller
{
    public function index(Request $request)
    {
        $this->authorize('viewAny', AttendanceRecord::class);

        $records = AttendanceRecord::query()
            ->with('justification')
            ->when($request->integer('student_id'), fn ($query, $studentId) => $query->where('student_id', $studentId))
            ->when(
                $request->user()->cannot('student.manage') && ! $request->user()->hasRole(['teacher', 'surveillant']),
                fn ($query) => $query->whereHas('student.guardians', fn ($q) => $q->whereKey($request->user()->id))
            )
            ->orderByDesc('date')
            ->paginate();

        return AttendanceRecordResource::collection($records);
    }

    public function store(StoreAttendanceRecordRequest $request)
    {
        $record = AttendanceRecord::create([
            ...$request->validated(),
            'recorded_by_user_id' => $request->user()->id,
        ]);

        return new AttendanceRecordResource($record);
    }

    public function show(AttendanceRecord $attendanceRecord)
    {
        $this->authorize('view', $attendanceRecord);

        return new AttendanceRecordResource($attendanceRecord->load('justification'));
    }

    /**
     * Le parent justifie une absence directement depuis l'app
     * (docs/PRODUCT_ARCHITECTURE.md §6, module Absences).
     */
    public function justify(JustifyAttendanceRequest $request, AttendanceRecord $attendanceRecord)
    {
        $justification = $attendanceRecord->justification()->create([
            ...$request->validated(),
            'submitted_by_user_id' => $request->user()->id,
        ]);

        return response()->json(['justification' => [
            'id' => $justification->id,
            'status' => $justification->status,
        ]], 201);
    }

    public function reviewJustification(ReviewAttendanceJustificationRequest $request, AttendanceRecord $attendanceRecord)
    {
        $justification = $attendanceRecord->justification()->firstOrFail();

        $justification->update([
            'status' => $request->validated('status'),
            'reviewed_by_user_id' => $request->user()->id,
            'reviewed_at' => now(),
        ]);

        return response()->json(['justification' => [
            'id' => $justification->id,
            'status' => $justification->status,
        ]]);
    }
}
