<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * Voir docs/PRODUCT_ARCHITECTURE.md §9 : le tenant n'est jamais choisi par
 * le client. `login` authentifie un compte `users` précis (l'email est
 * unique par école, pas globalement) ; si ce parent a des comptes dans
 * d'autres écoles (même parent_identity), `select-context` permet de
 * basculer entre eux sans ressaisir le mot de passe.
 */
class AuthController extends Controller
{
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        // L'email n'étant unique que par tenant, plusieurs comptes peuvent
        // correspondre (cas rare d'un même email réutilisé dans 2 écoles).
        $candidates = User::where('email', $credentials['email'])
            ->where('is_active', true)
            ->get()
            ->filter(fn (User $user) => Hash::check($credentials['password'], $user->password));

        if ($candidates->isEmpty()) {
            throw ValidationException::withMessages([
                'email' => ['Ces identifiants ne correspondent à aucun compte.'],
            ]);
        }

        $user = $candidates->first();
        $user->forceFill(['last_login_at' => now()])->save();

        return $this->respondWithToken($user);
    }

    public function selectContext(Request $request)
    {
        $validated = $request->validate([
            'user_id' => ['required', 'integer'],
        ]);

        $current = $request->user();
        $target = User::find($validated['user_id']);

        abort_if(
            ! $target
                || ! $current->parent_identity_id
                || $target->parent_identity_id !== $current->parent_identity_id,
            403,
            "Ce compte n'appartient pas à la même identité parent."
        );

        $current->currentAccessToken()->delete();
        $target->forceFill(['last_login_at' => now()])->save();

        return $this->respondWithToken($target);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Déconnecté.']);
    }

    private function respondWithToken(User $user)
    {
        $contexts = $user->parent_identity_id
            ? User::where('parent_identity_id', $user->parent_identity_id)
                ->with('tenant')
                ->get()
                ->map(fn (User $account) => [
                    'user_id' => $account->id,
                    'tenant_id' => $account->tenant_id,
                    'tenant_name' => $account->tenant?->name,
                ])
            : collect();

        return response()->json([
            'token' => $user->createToken(request()->userAgent() ?? 'mobile')->plainTextToken,
            'user' => new UserResource($user->load('tenant')),
            'contexts' => $contexts,
        ]);
    }
}
