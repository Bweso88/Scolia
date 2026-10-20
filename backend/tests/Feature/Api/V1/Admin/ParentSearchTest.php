<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * Recherche de parents existants (fratrie) pour StudentGuardianController,
 * qui accepte un `user_id` mais que le mobile n'avait aucun moyen de
 * retrouver — la direction devait recréer un compte parent, échouant sur
 * l'e-mail déjà pris.
 */
class ParentSearchTest extends TestCase
{
    use RefreshDatabase;

    public function test_direction_can_search_existing_parents_by_name_or_email(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $direction = User::factory()->for($tenant)->create();
        $direction->assignRole('school_admin');

        $parent = User::factory()->for($tenant)->create(['name' => 'Awa Diallo', 'email' => 'awa.diallo@example.test']);
        $parent->assignRole('parent');

        $autreParent = User::factory()->for($tenant)->create(['name' => 'Moussa Traoré']);
        $autreParent->assignRole('parent');

        $teacher = User::factory()->for($tenant)->create(['name' => 'Awa Enseignante']);
        $teacher->assignRole('teacher');

        $response = $this->actingAs($direction, 'sanctum')
            ->getJson('/api/v1/admin/parents?search=awa')
            ->assertOk();

        $noms = collect($response->json('data'))->pluck('name');
        $this->assertTrue($noms->contains('Awa Diallo'));
        $this->assertFalse($noms->contains('Moussa Traoré'));
        $this->assertFalse($noms->contains('Awa Enseignante'));
    }

    public function test_parents_of_another_tenant_are_not_returned(): void
    {
        $tenantA = Tenant::factory()->create();
        $tenantB = Tenant::factory()->create();

        app(PermissionRegistrar::class)->setPermissionsTeamId($tenantA->id);
        $direction = User::factory()->for($tenantA)->create();
        $direction->assignRole('school_admin');

        app(PermissionRegistrar::class)->setPermissionsTeamId($tenantB->id);
        $parentAutreEcole = User::factory()->for($tenantB)->create(['name' => 'Fatou Sow']);
        $parentAutreEcole->assignRole('parent');

        app(PermissionRegistrar::class)->setPermissionsTeamId($tenantA->id);

        $response = $this->actingAs($direction, 'sanctum')
            ->getJson('/api/v1/admin/parents?search=Fatou')
            ->assertOk();

        $this->assertCount(0, $response->json('data'));
    }

    public function test_a_teacher_without_student_manage_cannot_search_parents(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacher = User::factory()->for($tenant)->create();
        $teacher->assignRole('teacher');

        $this->actingAs($teacher, 'sanctum')
            ->getJson('/api/v1/admin/parents')
            ->assertForbidden();
    }
}
