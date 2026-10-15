<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreStudentRequest;
use App\Http\Requests\Api\V1\Admin\UpdateStudentRequest;
use App\Http\Resources\Api\V1\StudentResource;
use App\Models\Student;
use Illuminate\Http\Request;

class StudentController extends Controller
{
    public function index(Request $request)
    {
        $this->authorize('viewAny', Student::class);

        $students = Student::query()
            ->with('schoolClass')
            ->when($request->integer('school_class_id'), fn ($query, $classId) => $query->where('school_class_id', $classId))
            ->when(
                $request->user()->cannot('student.manage') && $request->user()->hasRole('parent'),
                // Un parent ne liste que ses propres enfants ; un enseignant
                // ou un surveillant voit les élèves de l'école (filtrables
                // par school_class_id ci-dessus).
                fn ($query) => $query->whereHas('guardians', fn ($q) => $q->whereKey($request->user()->id))
            )
            ->orderBy('last_name')
            ->paginate();

        return StudentResource::collection($students);
    }

    public function store(StoreStudentRequest $request)
    {
        $student = Student::create($request->validated());

        return new StudentResource($student->load('schoolClass'));
    }

    public function show(Student $student)
    {
        $this->authorize('view', $student);

        return new StudentResource($student->load('schoolClass'));
    }

    public function update(UpdateStudentRequest $request, Student $student)
    {
        $student->update($request->validated());

        return new StudentResource($student->load('schoolClass'));
    }

    public function destroy(Student $student)
    {
        $this->authorize('delete', $student);

        $student->delete();

        return response()->json(null, 204);
    }
}
