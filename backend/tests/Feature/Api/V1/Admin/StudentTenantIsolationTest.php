<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\StudentGuardian;
use App\Models\Tenant;
use App\Models\User;
use App\Support\Tenancy\TenantContext;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * Vérifie le mécanisme central de l'isolation multi-tenant
 * (docs/PRODUCT_ARCHITECTURE.md §6, point 6) : un administrateur d'une
 * école ne doit jamais pouvoir lire ou modifier les données d'une autre
 * école, même en devinant un identifiant valide.
 *
 * Note d'architecture : sur les routes à liaison implicite de modèle
 * (`{student}`), le middleware `SubstituteBindings` de Laravel résout le
 * modèle AVANT nos middlewares `auth`/`resolve.tenant` (il fait partie du
 * groupe `api`, exécuté en amont des middlewares de route). Le
 * TenantScope global n'a donc pas encore de contexte à ce stade et ne
 * filtre pas la liaison — c'est la Policy, vérifiée dans le contrôleur,
 * qui bloque effectivement l'accès cross-tenant (403). Le filtrage par
 * TenantScope reste actif pour toute requête normale (listes, création),
 * exécutée après resolve.tenant. C'est exactement le filet de sécurité
 * décrit au §6, point 5.
 */
class StudentTenantIsolationTest extends TestCase
{
    use RefreshDatabase;

    private function makeSchoolAdmin(Tenant $tenant): User
    {
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        return $admin;
    }

    public function test_admin_cannot_view_a_student_from_another_school(): void
    {
        $schoolA = Tenant::factory()->create();
        $schoolB = Tenant::factory()->create();

        $adminA = $this->makeSchoolAdmin($schoolA);

        $classB = SchoolClass::factory()->for($schoolB)->create();
        $studentB = Student::factory()->for($schoolB)->for($classB, 'schoolClass')->create();

        $this->actingAs($adminA, 'sanctum')
            ->getJson("/api/v1/admin/students/{$studentB->id}")
            ->assertForbidden();
    }

    public function test_admin_cannot_update_a_student_from_another_school(): void
    {
        $schoolA = Tenant::factory()->create();
        $schoolB = Tenant::factory()->create();

        $adminA = $this->makeSchoolAdmin($schoolA);

        $classB = SchoolClass::factory()->for($schoolB)->create();
        $studentB = Student::factory()->for($schoolB)->for($classB, 'schoolClass')->create();

        $this->actingAs($adminA, 'sanctum')
            ->patchJson("/api/v1/admin/students/{$studentB->id}", ['first_name' => 'Intrus'])
            ->assertForbidden();

        $this->assertDatabaseHas('students', [
            'id' => $studentB->id,
            'first_name' => $studentB->first_name,
        ]);
    }

    public function test_student_listing_only_returns_the_admins_own_school(): void
    {
        $schoolA = Tenant::factory()->create();
        $schoolB = Tenant::factory()->create();

        $adminA = $this->makeSchoolAdmin($schoolA);

        $classA = SchoolClass::factory()->for($schoolA)->create();
        Student::factory()->for($schoolA)->for($classA, 'schoolClass')->count(2)->create();

        $classB = SchoolClass::factory()->for($schoolB)->create();
        Student::factory()->for($schoolB)->for($classB, 'schoolClass')->count(3)->create();

        $response = $this->actingAs($adminA, 'sanctum')
            ->getJson('/api/v1/admin/students')
            ->assertOk();

        $this->assertCount(2, $response->json('data'));
    }

    public function test_a_parent_only_sees_their_own_children(): void
    {
        $tenant = Tenant::factory()->create();

        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);
        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $ownChild = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        $otherChild = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        // Le pivot student_guardians porte tenant_id : on passe par le modèle
        // Eloquent (BelongsToTenant le renseigne) plutôt que par attach(),
        // qui ferait un insert direct sans déclencher l'événement `creating`.
        // Hors requête HTTP, TenantContext n'est renseigné par aucun
        // middleware : on le fixe explicitement, comme le ferait
        // ResolveTenant en production.
        app(TenantContext::class)->set($tenant);

        StudentGuardian::create([
            'student_id' => $ownChild->id,
            'user_id' => $parent->id,
            'relationship_type' => 'parent',
            'is_primary_contact' => true,
        ]);

        $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/admin/students/{$ownChild->id}")
            ->assertOk();

        $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/admin/students/{$otherChild->id}")
            ->assertForbidden();
    }
}
