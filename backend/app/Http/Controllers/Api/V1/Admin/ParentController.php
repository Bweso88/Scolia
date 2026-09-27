<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
use Illuminate\Http\Request;

/**
 * Recherche de parents déjà existants dans l'école, pour les lier à un
 * autre élève (fratrie) sans recréer un compte — voir
 * StudentGuardianController::store, qui accepte déjà un `user_id`
 * existant, mais que le mobile n'avait aucun moyen de retrouver.
 */
class ParentController extends Controller
{
    public function index(Request $request)
    {
        abort_unless($request->user()->can('student.manage'), 403);

        $recherche = $request->string('search')->trim()->value();

        $parents = User::role('parent')
            ->when($recherche !== '', function ($query) use ($recherche) {
                $query->where(function ($q) use ($recherche) {
                    $q->where('name', 'like', "%{$recherche}%")
                        ->orWhere('email', 'like', "%{$recherche}%");
                });
            })
            ->orderBy('name')
            ->limit(20)
            ->get();

        return UserResource::collection($parents);
    }
}
