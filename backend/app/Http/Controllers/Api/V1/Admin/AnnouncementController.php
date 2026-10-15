<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreAnnouncementRequest;
use App\Http\Resources\Api\V1\AnnouncementResource;
use App\Models\Announcement;
use App\Models\User;
use App\Notifications\NewAnnouncementNotification;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Storage;

class AnnouncementController extends Controller
{
    public function index()
    {
        $this->authorize('viewAny', Announcement::class);

        $user = request()->user();

        $announcements = Announcement::query()
            ->with('author')
            ->notArchivedBy($user->id)
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
            $photoPath = $request->hasFile('photo')
                ? $request->file('photo')->store("tenants/{$request->user()->tenant_id}/announcements", 'public')
                : null;

            $announcement = Announcement::create([
                'author_user_id' => $request->user()->id,
                'title' => $request->validated('title'),
                'body' => $request->validated('body'),
                'category' => $request->validated('category'),
                'published_at' => now(),
                'photo_path' => $photoPath,
            ]);

            $announcement->targets()->createMany($request->validated('targets'));

            return $announcement;
        });

        Notification::send($this->resolveRecipients($announcement), new NewAnnouncementNotification($announcement));

        return new AnnouncementResource($announcement->load('author'));
    }

    public function show(Announcement $announcement)
    {
        $this->authorize('view', $announcement);

        return new AnnouncementResource($announcement->load('author', 'targets'));
    }

    /**
     * Masquer l'annonce de ma propre liste — réversible, sans effet pour
     * les autres destinataires.
     */
    public function archive(Announcement $announcement)
    {
        $this->authorize('archive', $announcement);

        $announcement->archiverPour(request()->user()->id);

        return response()->json(null, 204);
    }

    public function unarchive(Announcement $announcement)
    {
        $this->authorize('archive', $announcement);

        $announcement->desarchiverPour(request()->user()->id);

        return response()->json(null, 204);
    }

    public function destroy(Announcement $announcement)
    {
        $this->authorize('delete', $announcement);

        if ($announcement->photo_path) {
            Storage::disk('public')->delete($announcement->photo_path);
        }

        $announcement->delete();

        return response()->json(null, 204);
    }

    private function resolveRecipients(Announcement $announcement): Collection
    {
        $recipients = collect();

        foreach ($announcement->targets as $target) {
            $recipients = $recipients->merge(match ($target->target_type) {
                'all' => User::where('tenant_id', $announcement->tenant_id)->get(),
                'user' => User::where('id', $target->target_id)->get(),
                'school_class' => User::whereHas('students', fn ($q) => $q->where('school_class_id', $target->target_id))->get(),
                default => collect(),
            });
        }

        return $recipients->unique('id');
    }
}
