<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreGradeRequest;
use App\Http\Requests\Api\V1\Admin\UpdateGradeRequest;
use App\Http\Resources\Api\V1\GradeResource;
use App\Models\Grade;
use Illuminate\Http\Request;

class GradeController extends Controller
{
    public function index(Request $request)
    {
        $this->authorize('viewAny', Grade::class);

        $grades = Grade::query()
            ->with(['subject', 'gradingPeriod'])
            ->when($request->integer('student_id'), fn ($query, $studentId) => $query->where('student_id', $studentId))
            ->orderByDesc('created_at')
            ->paginate();

        return GradeResource::collection($grades);
    }

    public function store(StoreGradeRequest $request)
    {
        $grade = Grade::create([
            ...$request->validated(),
            'entered_by_user_id' => $request->user()->id,
        ]);

        return new GradeResource($grade->load(['subject', 'gradingPeriod']));
    }

    public function update(UpdateGradeRequest $request, Grade $grade)
    {
        $grade->update($request->validated());

        return new GradeResource($grade->load(['subject', 'gradingPeriod']));
    }
}
