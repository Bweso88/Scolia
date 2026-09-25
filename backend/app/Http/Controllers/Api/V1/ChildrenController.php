<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\AnnouncementResource;
use App\Http\Resources\Api\V1\AttendanceRecordResource;
use App\Http\Resources\Api\V1\BehaviorObservationResource;
use App\Http\Resources\Api\V1\GradeResource;
use App\Http\Resources\Api\V1\HomeworkResource;
use App\Http\Resources\Api\V1\StudentResource;
use App\Http\Resources\Api\V1\TimetableSlotResource;
use App\Models\AcademicEvent;
use App\Models\Announcement;
use App\Models\AttendanceRecord;
use App\Models\BehaviorObservation;
use App\Models\Homework;
use App\Models\Message;
use App\Models\Student;
use App\Models\TimetableSlot;
use Illuminate\Http\Request;

/**
 * Consultation par un parent des données de ses propres enfants
 * (docs/PRODUCT_ARCHITECTURE.md §9 et §12). Toute route ici est protégée
 * par la même StudentPolicy que le back-office : un parent n'accède qu'à
 * ses enfants, un membre du personnel accède à toute l'école.
 */
class ChildrenController extends Controller
{
    public function index(Request $request)
    {
        $children = $request->user()->students()->with('schoolClass')->get();

        return StudentResource::collection($children);
    }

    /**
     * Simule l'activation payante par enfant (docs/PRODUCT_ARCHITECTURE.md
     * §18) : un parent voit toujours ses enfants dans la liste (index),
     * mais aucun détail tant que l'enfant n'est pas activé. Le personnel
     * de l'école n'est jamais bloqué par cette vérification.
     */
    private function ensureActivatedForParent(Request $request, Student $student): void
    {
        abort_if(
            $request->user()->hasRole('parent') && ! $student->isActivated(),
            403,
            "Cet enfant n'est pas encore activé. Contactez l'administration de l'école."
        );
    }

    public function dashboard(Request $request, Student $student)
    {
        $this->authorize('view', $student);
        $this->ensureActivatedForParent($request, $student);

        $today = today();

        return response()->json([
            'student' => new StudentResource($student->load('schoolClass')),
            'homeworks_today' => HomeworkResource::collection(
                Homework::where('school_class_id', $student->school_class_id)
                    ->whereDate('due_date', $today)
                    ->with(['subject', 'teacher.user'])
                    ->get()
            ),
            'latest_messages' => Message::whereHas('conversation', fn ($q) => $q->where('student_id', $student->id))
                ->latest()
                ->limit(3)
                ->pluck('body'),
            'recent_behavior' => BehaviorObservationResource::collection(
                $student->behaviorObservations()->where('visible_to_parent', true)->latest('occurred_at')->limit(3)->get()
            ),
            'recent_attendance' => AttendanceRecordResource::collection(
                $student->attendanceRecords()->latest('date')->limit(3)->get()
            ),
            'next_event' => AcademicEvent::where('start_date', '>=', $today)->orderBy('start_date')->first(),
            'today_timetable' => TimetableSlotResource::collection(
                TimetableSlot::where('school_class_id', $student->school_class_id)
                    ->where('day_of_week', $today->dayOfWeekIso)
                    ->orderBy('start_time')
                    ->with(['subject', 'teacher.user'])
                    ->get()
            ),
        ]);
    }

    /**
     * `range` : today | tomorrow | week (défaut) | late.
     */
    public function homeworks(Request $request, Student $student)
    {
        $this->authorize('view', $student);
        $this->ensureActivatedForParent($request, $student);

        $today = today();

        $query = Homework::where('school_class_id', $student->school_class_id)
            ->with(['subject', 'teacher.user']);

        match ($request->string('range', 'week')->value()) {
            'today' => $query->whereDate('due_date', $today),
            'tomorrow' => $query->whereDate('due_date', $today->copy()->addDay()),
            'late' => $query->whereDate('due_date', '<', $today),
            default => $query->whereBetween('due_date', [$today, $today->copy()->addWeek()]),
        };

        return HomeworkResource::collection($query->orderBy('due_date')->get());
    }

    public function behavior(Request $request, Student $student)
    {
        $this->authorize('view', $student);
        $this->ensureActivatedForParent($request, $student);

        $observations = BehaviorObservation::where('student_id', $student->id)
            ->where('visible_to_parent', true)
            ->with('author')
            ->orderByDesc('occurred_at')
            ->paginate();

        return BehaviorObservationResource::collection($observations);
    }

    public function attendance(Request $request, Student $student)
    {
        $this->authorize('view', $student);
        $this->ensureActivatedForParent($request, $student);

        $records = AttendanceRecord::where('student_id', $student->id)
            ->with('justification')
            ->orderByDesc('date')
            ->paginate();

        return AttendanceRecordResource::collection($records);
    }

    public function timetable(Request $request, Student $student)
    {
        $this->authorize('view', $student);
        $this->ensureActivatedForParent($request, $student);

        $slots = TimetableSlot::where('school_class_id', $student->school_class_id)
            ->with(['subject', 'teacher.user'])
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get();

        return TimetableSlotResource::collection($slots);
    }

    /**
     * Le module notes/bulletins est activable/désactivable par école
     * (docs/PRODUCT_ARCHITECTURE.md §4 et §18) sans changement de code.
     */
    public function grades(Request $request, Student $student)
    {
        $this->authorize('view', $student);
        $this->ensureActivatedForParent($request, $student);
        abort_unless($student->tenant->isModuleEnabled('notes'), 403, "Le module notes n'est pas activé pour cette école.");

        $grades = $student->grades()->with(['subject', 'gradingPeriod'])->orderByDesc('created_at')->paginate();

        return GradeResource::collection($grades);
    }

    public function announcements(Request $request, Student $student)
    {
        $this->authorize('view', $student);
        $this->ensureActivatedForParent($request, $student);

        $announcements = AnnouncementResource::collection(
            Announcement::whereHas('targets', function ($q) use ($student) {
                $q->where('target_type', 'all')
                    ->orWhere(fn ($qq) => $qq->where('target_type', 'school_class')->where('target_id', $student->school_class_id));
            })->orderByDesc('published_at')->paginate()
        );

        return $announcements;
    }
}
