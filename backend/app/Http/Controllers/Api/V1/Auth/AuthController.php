<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\TenantSetting;
use App\Models\User;
use App\Support\Talenda\PhoneNumber;
use App\Support\Talenda\TalendaClient;
use App\Support\Talenda\TalendaUnavailable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Spatie\Permission\PermissionRegistrar;

/**
 * Voir docs/PRODUCT_ARCHITECTURE.md §9 : le tenant n'est jamais choisi par
 * le client. `login` authentifie un compte `users` précis, par e-mail ou
 * téléphone (l'email est unique par école, pas globalement) ; si ce parent a des comptes dans
 * d'autres écoles (même parent_identity), `select-context` permet de
 * basculer entre eux sans ressaisir le mot de passe.
 */
class AuthController extends Controller
{
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'login' => ['required_without:email', 'nullable', 'string', 'max:255'],
            'email' => ['required_without:login', 'nullable', 'string', 'max:255'],
            'password' => ['required', 'string'],
        ]);

        $login = trim((string) ($credentials['login'] ?? $credentials['email']));

        // L'email n'étant unique que par tenant, plusieurs comptes peuvent
        // correspondre (cas rare d'un même email réutilisé dans 2 écoles).
        $candidates = User::query()
            ->where('is_active', true)
            ->where(fn ($query) => $query->where('email', $login)->orWhereIn('phone', PhoneNumber::variants($login)))
            ->get();

        $talendaUnavailable = false;
        $user = $candidates->first(function (User $candidate) use ($login, $credentials, &$talendaUnavailable): bool {
            if (! $candidate->isManagedByTalenda()) {
                return Hash::check($credentials['password'], $candidate->password);
            }

            // Compte venu de Talenda : un seul mot de passe, celui de
            // Talenda (docs/JONCTION_TALENDA.md).
            try {
                return $this->talendaAccepts($candidate, $login, $credentials['password']);
            } catch (TalendaUnavailable) {
                $talendaUnavailable = true;

                return false;
            }
        });

        if ($user === null) {
            throw ValidationException::withMessages([
                'email' => [$talendaUnavailable
                    ? 'Connexion impossible pour le moment : le service de l\'école ne répond pas. Réessayez dans quelques minutes.'
                    : 'Ces identifiants ne correspondent à aucun compte.'],
            ]);
        }

        $user->forceFill(['last_login_at' => now()])->save();

        return $this->respondWithToken($user);
    }

    /**
     * @throws TalendaUnavailable
     */
    private function talendaAccepts(User $user, string $login, string $password): bool
    {
        $settings = TenantSetting::query()->where('tenant_id', $user->tenant_id)->first();

        if ($user->talenda_account_uuid === null || $settings === null || ! $settings->isConnectedToTalenda()) {
            return false;
        }

        $account = (new TalendaClient($settings))->checkCredentials($login, $password);

        return $account !== null && $account['account_uuid'] === $user->talenda_account_uuid;
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
        // Hors de resolve.tenant (routes d'auth), le registrar spatie n'a
        // pas encore de team_id : sans ceci, $user->roles reviendrait vide.
        app(PermissionRegistrar::class)->setPermissionsTeamId($user->tenant_id);

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
            'user' => new UserResource($user->load(['tenant.settings', 'roles', 'teacher.schoolClasses'])),
            'contexts' => $contexts,
        ]);
    }
}
