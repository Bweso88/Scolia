<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreSchoolClassRequest;
use App\Http\Requests\Api\V1\Admin\UpdateSchoolClassRequest;
use App\Http\Resources\Api\V1\SchoolClassResource;
use App\Models\SchoolClass;

class SchoolClassController extends Controller
{
    public function index()
    {
        $this->authorize('viewAny', SchoolClass::class);

        $classes = SchoolClass::query()
            ->with(['schoolYear', 'homeroomTeacher.user'])
            ->withCount('students')
            ->orderBy('name')
            ->get();

        return SchoolClassResource::collection($classes);
    }

    public function store(StoreSchoolClassRequest $request)
    {
        $class = SchoolClass::create($request->validated());

        return new SchoolClassResource($class->load(['schoolYear', 'homeroomTeacher.user']));
    }

    public function show(SchoolClass $schoolClass)
    {
        $this->authorize('view', $schoolClass);

        return new SchoolClassResource($schoolClass->load(['schoolYear', 'homeroomTeacher.user'])->loadCount('students'));
    }

    public function update(UpdateSchoolClassRequest $request, SchoolClass $schoolClass)
    {
        $schoolClass->update($request->validated());

        return new SchoolClassResource($schoolClass->load(['schoolYear', 'homeroomTeacher.user']));
    }

    public function destroy(SchoolClass $schoolClass)
    {
        $this->authorize('delete', $schoolClass);

        $schoolClass->delete();

        return response()->json(null, 204);
    }
}
