<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreStudentGuardianRequest;
use App\Http\Resources\Api\V1\StudentGuardianResource;
use App\Models\Student;
use App\Models\StudentGuardian;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class StudentGuardianController extends Controller
{
    public function index(Student $student)
    {
        $this->authorize('view', $student);

        return StudentGuardianResource::collection(
            $student->studentGuardians()->with('guardianUser')->get()
        );
    }

    public function store(StoreStudentGuardianRequest $request, Student $student)
    {
        $guardian = DB::transaction(function () use ($request, $student) {
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

            if (! $user->hasRole('parent')) {
                $user->assignRole('parent');
            }

            return $student->studentGuardians()->create([
                'user_id' => $user->id,
                'relationship_type' => $request->validated('relationship_type'),
                'is_primary_contact' => $request->boolean('is_primary_contact'),
            ]);
        });

        return new StudentGuardianResource($guardian->load('guardianUser'));
    }

    public function destroy(Student $student, StudentGuardian $guardian)
    {
        $this->authorize('update', $student);
        abort_if($guardian->student_id !== $student->id, 404);

        $guardian->delete();

        return response()->json(null, 204);
    }
}
