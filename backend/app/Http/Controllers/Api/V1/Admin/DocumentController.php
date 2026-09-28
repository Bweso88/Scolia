<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreDocumentRequest;
use App\Http\Resources\Api\V1\DocumentResource;
use App\Models\Document;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;

/**
 * Fichiers stockés hors du webroot (disque `local`, jamais `public`) et
 * jamais servis par un chemin direct : le téléchargement passe par une URL
 * signée à courte durée de vie (docs/PRODUCT_ARCHITECTURE.md §17).
 */
class DocumentController extends Controller
{
    public function index(Request $request)
    {
        $this->authorize('viewAny', Document::class);

        $user = $request->user();

        $documents = Document::query()
            ->when($user->cannot('document.manage'), fn ($query) => $query->where(function ($q) use ($user) {
                $q->where('visible_to', 'all')
                    ->orWhere(fn ($qq) => $qq->where('visible_to', 'user')->where('target_id', $user->id))
                    ->orWhere(fn ($qq) => $qq->where('visible_to', 'student')->whereIn('target_id', $user->students()->pluck('students.id')))
                    ->orWhere(fn ($qq) => $qq->where('visible_to', 'school_class')->whereIn('target_id', $user->students()->pluck('school_class_id')));
            }))
            ->orderByDesc('created_at')
            ->paginate();

        return DocumentResource::collection($documents);
    }

    public function store(StoreDocumentRequest $request)
    {
        $path = $request->file('file')->store("tenants/{$request->user()->tenant_id}/documents", 'local');

        $document = Document::create([
            ...$request->safe()->except('file'),
            'file_path' => $path,
            'uploaded_by_user_id' => $request->user()->id,
        ]);

        return new DocumentResource($document);
    }

    public function show(Document $document)
    {
        $this->authorize('view', $document);

        return (new DocumentResource($document))->additional([
            'download_url' => URL::temporarySignedRoute(
                'api.v1.admin.documents.stream',
                now()->addMinutes(5),
                ['document' => $document->id]
            ),
        ]);
    }

    /**
     * Route signée, sans middleware d'authentification : la signature,
     * générée uniquement après vérification de la policy dans `show`,
     * fait foi et expire après 5 minutes.
     */
    public function stream(Document $document)
    {
        return Storage::disk('local')->download($document->file_path, $document->title);
    }

    public function destroy(Document $document)
    {
        $this->authorize('delete', $document);

        Storage::disk('local')->delete($document->file_path);
        $document->delete();

        return response()->json(null, 204);
    }
}
