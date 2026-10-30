<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreGradingPeriodRequest;
use App\Http\Resources\Api\V1\GradingPeriodResource;
use App\Models\GradingPeriod;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class GradingPeriodController extends Controller
{
    public function index()
    {
        abort_unless(request()->user()->can('grade.view'), 403);

        return GradingPeriodResource::collection(GradingPeriod::orderByDesc('id')->get());
    }

    public function store(StoreGradingPeriodRequest $request)
    {
        $period = GradingPeriod::create($request->validated());

        return new GradingPeriodResource($period);
    }

    public function update(Request $request, GradingPeriod $gradingPeriod)
    {
        abort_unless($request->user()->can('grade.manage'), 403);

        $request->validate(['label' => ['required', 'string', 'max:100']]);
        $gradingPeriod->update($request->only('label'));

        return new GradingPeriodResource($gradingPeriod);
    }

    public function destroy(Request $request, GradingPeriod $gradingPeriod)
    {
        abort_unless($request->user()->can('grade.manage'), 403);

        if ($gradingPeriod->grades()->exists()) {
            throw ValidationException::withMessages([
                'grading_period' => 'Cette période contient déjà des notes, elle ne peut pas être supprimée.',
            ]);
        }

        $gradingPeriod->delete();

        return response()->noContent();
    }
}
