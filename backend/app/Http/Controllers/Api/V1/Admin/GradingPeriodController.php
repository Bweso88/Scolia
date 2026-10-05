<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreGradingPeriodRequest;
use App\Http\Resources\Api\V1\GradingPeriodResource;
use App\Models\GradingPeriod;

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
}
