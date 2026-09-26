<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreSubjectRequest;
use App\Http\Resources\Api\V1\SubjectResource;
use App\Models\Subject;
use Illuminate\Http\Request;

/**
 * Lecture ouverte à tout utilisateur authentifié de l'école (donnée de
 * référence non sensible) ; seule la direction peut créer/modifier/
 * supprimer (permission schoolclass.manage).
 */
class SubjectController extends Controller
{
    public function index()
    {
        return SubjectResource::collection(Subject::orderBy('name')->get());
    }

    public function store(StoreSubjectRequest $request)
    {
        $subject = Subject::create($request->validated());

        return new SubjectResource($subject);
    }

    public function update(Request $request, Subject $subject)
    {
        $this->authorize('update', $subject);

        $validated = $request->validate(['name' => ['required', 'string', 'max:255']]);
        $subject->update($validated);

        return new SubjectResource($subject);
    }

    public function destroy(Subject $subject)
    {
        $this->authorize('delete', $subject);

        $subject->delete();

        return response()->json(null, 204);
    }
}
