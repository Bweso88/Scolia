<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\StudentResource;
use App\Models\Student;
use Illuminate\Http\Request;

/**
 * Simule l'activation payante par enfant (docs/PRODUCT_ARCHITECTURE.md
 * §18) : la vraie facturation reste hors MVP, mais l'administration doit
 * pouvoir basculer l'état d'un enfant pour le tester. Réservé à
 * `student.manage` (school_admin, direction), jamais au parent lui-même.
 */
class StudentActivationController extends Controller
{
    public function update(Request $request, Student $student)
    {
        $this->authorize('update', $student);

        $validated = $request->validate([
            'active' => ['required', 'boolean'],
        ]);

        $student->activated_at = $validated['active'] ? now() : null;
        $student->save();

        return new StudentResource($student->load('schoolClass'));
    }
}
