<?php

namespace Tests\Feature\Api\V1\Auth;

use App\Models\ParentIdentity;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class LoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_user_can_login_with_valid_credentials(): void
    {
        $tenant = Tenant::factory()->create();
        $user = User::factory()->for($tenant)->create(['password' => Hash::make('correct-password')]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'correct-password',
        ]);

        $response->assertOk()->assertJsonStructure(['token', 'user', 'contexts']);
    }

    public function test_login_fails_with_invalid_credentials(): void
    {
        $tenant = Tenant::factory()->create();
        $user = User::factory()->for($tenant)->create(['password' => Hash::make('correct-password')]);

        $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'wrong-password',
        ])->assertUnprocessable();
    }

    /**
     * Un parent avec des enfants dans deux écoles bascule d'un contexte à
     * l'autre sans ressaisir son mot de passe (docs/PRODUCT_ARCHITECTURE.md §9).
     */
    public function test_a_multi_school_parent_can_switch_context_without_reauthenticating(): void
    {
        $identity = ParentIdentity::factory()->create();

        $tenantA = Tenant::factory()->create();
        $tenantB = Tenant::factory()->create();

        $accountA = User::factory()->for($tenantA)->create([
            'parent_identity_id' => $identity->id,
            'password' => Hash::make('secret'),
        ]);
        $accountB = User::factory()->for($tenantB)->create([
            'parent_identity_id' => $identity->id,
        ]);

        $login = $this->postJson('/api/v1/auth/login', [
            'email' => $accountA->email,
            'password' => 'secret',
        ])->assertOk();

        $token = $login->json('token');

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/v1/auth/select-context', ['user_id' => $accountB->id])
            ->assertOk()
            ->assertJsonPath('user.id', $accountB->id);
    }
}
