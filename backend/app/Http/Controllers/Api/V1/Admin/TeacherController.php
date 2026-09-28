<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreTeacherRequest;
use App\Http\Requests\Api\V1\Admin\UpdateTeacherRequest;
use App\Http\Resources\Api\V1\TeacherResource;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class TeacherController extends Controller
{
    public function index()
    {
        $this->authorize('viewAny', Teacher::class);

        $teachers = Teacher::query()
            ->with(['user', 'assignments.schoolClass', 'assignments.subject'])
            ->get();

        return TeacherResource::collection($teachers);
    }

    public function store(StoreTeacherRequest $request)
    {
        $teacher = DB::transaction(function () use ($request) {
            if ($request->filled('user_id')) {
                $user = User::findOrFail($request->validated('user_id'));
            } else {
                $user = User::create([
                    'name' => $request->validated('name'),
                    'email' => $request->validated('email'),
                    'password' => Hash::make($request->validated('password')),
                    'is_active' => true,
                ]);
            }

            if (! $user->hasRole('teacher')) {
                $user->assignRole('teacher');
            }

            $teacher = Teacher::create([
                'user_id' => $user->id,
                'employee_number' => $request->validated('employee_number'),
            ]);

            foreach ($request->validated('assignments', []) as $assignment) {
                $teacher->assignments()->create($assignment);
            }

            return $teacher;
        });

        return new TeacherResource($teacher->load(['user', 'assignments.schoolClass', 'assignments.subject']));
    }

    public function show(Teacher $teacher)
    {
        $this->authorize('view', $teacher);

        return new TeacherResource($teacher->load(['user', 'assignments.schoolClass', 'assignments.subject']));
    }

    public function update(UpdateTeacherRequest $request, Teacher $teacher)
    {
        $teacher->update(['employee_number' => $request->validated('employee_number', $teacher->employee_number)]);

        if ($request->has('assignments')) {
            $teacher->assignments()->delete();
            foreach ($request->validated('assignments', []) as $assignment) {
                $teacher->assignments()->create($assignment);
            }
        }

        return new TeacherResource($teacher->load(['user', 'assignments.schoolClass', 'assignments.subject']));
    }

    public function destroy(Teacher $teacher)
    {
        $this->authorize('delete', $teacher);

        $teacher->delete();

        return response()->json(null, 204);
    }
}
