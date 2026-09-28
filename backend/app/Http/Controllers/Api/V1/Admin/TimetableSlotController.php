<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreTimetableSlotRequest;
use App\Http\Requests\Api\V1\Admin\UpdateTimetableSlotRequest;
use App\Http\Resources\Api\V1\TimetableSlotResource;
use App\Models\TimetableSlot;
use Illuminate\Http\Request;

class TimetableSlotController extends Controller
{
    public function index(Request $request)
    {
        $this->authorize('viewAny', TimetableSlot::class);

        $slots = TimetableSlot::query()
            ->with(['subject', 'teacher.user'])
            ->when($request->integer('school_class_id'), fn ($query, $classId) => $query->where('school_class_id', $classId))
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get();

        return TimetableSlotResource::collection($slots);
    }

    public function store(StoreTimetableSlotRequest $request)
    {
        $slot = TimetableSlot::create($request->validated());

        return new TimetableSlotResource($slot->load(['subject', 'teacher.user']));
    }

    public function show(TimetableSlot $timetableSlot)
    {
        $this->authorize('view', $timetableSlot);

        return new TimetableSlotResource($timetableSlot->load(['subject', 'teacher.user']));
    }

    public function update(UpdateTimetableSlotRequest $request, TimetableSlot $timetableSlot)
    {
        $timetableSlot->update($request->validated());

        return new TimetableSlotResource($timetableSlot->load(['subject', 'teacher.user']));
    }

    public function destroy(TimetableSlot $timetableSlot)
    {
        $this->authorize('delete', $timetableSlot);

        $timetableSlot->delete();

        return response()->json(null, 204);
    }
}
