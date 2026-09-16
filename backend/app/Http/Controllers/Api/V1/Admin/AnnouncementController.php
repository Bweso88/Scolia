<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreAnnouncementRequest;
use App\Http\Resources\Api\V1\AnnouncementResource;
use App\Models\Announcement;
use Illuminate\Support\Facades\DB;

class AnnouncementController extends Controller
{
    public function index()
    {
        $this->authorize('viewAny', Announcement::class);

        $user = request()->user();

        $announcements = Announcement::query()
            ->with('author')
            ->when(
                $user->cannot('announcement.publish'),
                fn ($query) => $query->whereHas('targets', function ($q) use ($user) {
                    $q->where('target_type', 'all')
                        ->orWhere(fn ($qq) => $qq->where('target_type', 'user')->where('target_id', $user->id))
                        ->orWhere(fn ($qq) => $qq->where('target_type', 'school_class')->whereIn(
                            'target_id',
                            $user->students()->pluck('school_class_id')
                        ));
                })
            )
            ->orderByDesc('published_at')
            ->paginate();

        return AnnouncementResource::collection($announcements);
    }

    /**
     * Ciblage polymorphique simple (§7/§8) : all | school_class | user.
     * Le ciblage "groupe" mentionné dans la doc reste un chantier V2.
     */
    public function store(StoreAnnouncementRequest $request)
    {
        $announcement = DB::transaction(function () use ($request) {
            $announcement = Announcement::create([
                'author_user_id' => $request->user()->id,
                'title' => $request->validated('title'),
                'body' => $request->validated('body'),
                'category' => $request->validated('category'),
                'published_at' => now(),
            ]);

            $announcement->targets()->createMany($request->validated('targets'));

            return $announcement;
        });

        return new AnnouncementResource($announcement->load('author'));
    }

    public function show(Announcement $announcement)
    {
        $this->authorize('view', $announcement);

        return new AnnouncementResource($announcement->load('author', 'targets'));
    }
}
