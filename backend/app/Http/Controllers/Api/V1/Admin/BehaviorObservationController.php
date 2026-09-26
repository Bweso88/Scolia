<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreBehaviorObservationRequest;
use App\Http\Resources\Api\V1\BehaviorObservationResource;
use App\Models\BehaviorObservation;
use App\Notifications\NewBehaviorObservationNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Notification;

class BehaviorObservationController extends Controller
{
    public function index(Request $request)
    {
        $this->authorize('viewAny', BehaviorObservation::class);

        $observations = BehaviorObservation::query()
            ->with('author')
            ->when($request->integer('student_id'), fn ($query, $studentId) => $query->where('student_id', $studentId))
            ->when(
                $request->user()->cannot('student.manage') && ! $request->user()->hasRole(['teacher', 'surveillant']),
                // Un parent ne voit que les observations visibles de ses propres enfants.
                fn ($query) => $query->where('visible_to_parent', true)
                    ->whereHas('student.guardians', fn ($q) => $q->whereKey($request->user()->id))
            )
            ->orderByDesc('occurred_at')
            ->paginate();

        return BehaviorObservationResource::collection($observations);
    }

    public function store(StoreBehaviorObservationRequest $request)
    {
        $observation = BehaviorObservation::create([
            ...$request->validated(),
            'author_user_id' => $request->user()->id,
            'occurred_at' => $request->validated('occurred_at') ?? now(),
            'visible_to_parent' => $request->validated('visible_to_parent') ?? true,
        ]);

        if ($observation->visible_to_parent) {
            Notification::send($observation->student->guardians, new NewBehaviorObservationNotification($observation));
        }

        return new BehaviorObservationResource($observation->load('author'));
    }

    public function show(BehaviorObservation $behaviorObservation)
    {
        $this->authorize('view', $behaviorObservation);

        return new BehaviorObservationResource($behaviorObservation->load('author'));
    }

    public function destroy(BehaviorObservation $behaviorObservation)
    {
        $this->authorize('delete', $behaviorObservation);

        $behaviorObservation->delete();

        return response()->json(null, 204);
    }
}
