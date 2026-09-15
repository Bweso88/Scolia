<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreHomeworkRequest;
use App\Http\Requests\Api\V1\Admin\UpdateHomeworkRequest;
use App\Http\Resources\Api\V1\HomeworkResource;
use App\Models\Homework;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HomeworkController extends Controller
{
    public function index(Request $request)
    {
        $this->authorize('viewAny', Homework::class);

        $homeworks = Homework::query()
            ->with(['subject', 'schoolClass', 'teacher.user'])
            ->when($request->integer('school_class_id'), fn ($query, $classId) => $query->where('school_class_id', $classId))
            ->orderByDesc('due_date')
            ->paginate();

        return HomeworkResource::collection($homeworks);
    }

    /**
     * La publication d'un devoir génère immédiatement le statut "pending"
     * pour chaque élève de la classe (voir docs/PRODUCT_ARCHITECTURE.md §7,
     * table homework_status) — c'est ce qui alimente les vues "à faire" /
     * "en retard" côté parent.
     */
    public function store(StoreHomeworkRequest $request)
    {
        $homework = DB::transaction(function () use ($request) {
            $homework = Homework::create([
                ...$request->validated(),
                'published_at' => now(),
            ]);

            $studentIds = Student::where('school_class_id', $homework->school_class_id)
                ->where('status', 'active')
                ->pluck('id');

            $homework->statuses()->createMany(
                $studentIds->map(fn ($studentId) => ['student_id' => $studentId])->all()
            );

            return $homework;
        });

        return new HomeworkResource($homework->load(['subject', 'schoolClass', 'teacher.user']));
    }

    public function show(Homework $homework)
    {
        $this->authorize('view', $homework);

        return new HomeworkResource($homework->load(['subject', 'schoolClass', 'teacher.user', 'attachments']));
    }

    public function update(UpdateHomeworkRequest $request, Homework $homework)
    {
        $homework->update($request->validated());

        return new HomeworkResource($homework->load(['subject', 'schoolClass', 'teacher.user']));
    }

    public function destroy(Homework $homework)
    {
        $this->authorize('delete', $homework);

        $homework->delete();

        return response()->json(null, 204);
    }
}
