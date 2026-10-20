<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use App\Models\Scopes\TenantScope;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class DeviceTokenController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'fcm_token' => ['required', 'string'],
            'platform' => ['required', Rule::in(['android', 'ios'])],
        ]);

        // fcm_token est unique au niveau plateforme (un appareil), pas par
        // école : un même appareil peut être réinstallé/reconnecté sous un
        // autre compte, y compris d'une autre école. On lève donc
        // explicitement le TenantScope pour retrouver et réattribuer
        // l'éventuel enregistrement existant plutôt que de heurter la
        // contrainte d'unicité — exception documentée (§6), aucune donnée
        // d'une autre école n'est exposée en retour.
        DeviceToken::withoutGlobalScope(TenantScope::class)
            ->where('fcm_token', $validated['fcm_token'])
            ->delete();

        $request->user()->deviceTokens()->create([
            'fcm_token' => $validated['fcm_token'],
            'platform' => $validated['platform'],
            'last_seen_at' => now(),
        ]);

        return response()->json(['message' => 'Appareil enregistré.'], 201);
    }

    public function destroy(Request $request, string $fcmToken)
    {
        $request->user()->deviceTokens()->where('fcm_token', $fcmToken)->delete();

        return response()->json(null, 204);
    }
}
