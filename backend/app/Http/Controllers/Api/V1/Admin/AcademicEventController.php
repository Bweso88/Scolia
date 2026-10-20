<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreAcademicEventRequest;
use App\Http\Resources\Api\V1\AcademicEventResource;
use App\Models\AcademicEvent;

/**
 * Événements du calendrier scolaire — section "Agenda" (docs/PRODUCT_ARCHITECTURE.md).
 * Ouvert à tout utilisateur du tenant (parent inclus) en lecture, création
 * réservée à la direction/l'administration (`timetable.manage`).
 */
class AcademicEventController extends Controller
{
    public function index()
    {
        $this->authorize('viewAny', AcademicEvent::class);

        $events = AcademicEvent::query()
            ->where('end_date', '>=', today())
            ->orderBy('start_date')
            ->paginate();

        return AcademicEventResource::collection($events);
    }

    public function store(StoreAcademicEventRequest $request)
    {
        $event = AcademicEvent::create($request->validated());

        return new AcademicEventResource($event);
    }

    public function destroy(AcademicEvent $academicEvent)
    {
        $this->authorize('delete', $academicEvent);

        $academicEvent->delete();

        return response()->json(null, 204);
    }
}
