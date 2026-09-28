<?php

namespace Tests\Feature\Api\V1;

use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * Simulation de l'activation payante par enfant (docs/PRODUCT_ARCHITECTURE.md
 * §18) : la vraie facturation reste hors MVP, seul le bascule admin compte ici.
 */
class StudentActivationTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_parent_cannot_see_details_of_an_inactive_child(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $child = Student::factory()->inactive()->for($tenant)->for($class, 'schoolClass')->create();
        $child->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        // La liste reste visible (le parent doit pouvoir voir qu'il a un
        // enfant à activer), mais le détail est bloqué.
        $index = $this->actingAs($parent, 'sanctum')
            ->getJson('/api/v1/children')
            ->assertOk();
        $this->assertFalse($index->json('data.0.is_activated'));

        $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/children/{$child->id}/dashboard")
            ->assertForbidden();
    }

    public function test_school_admin_can_activate_a_child_and_the_parent_gets_access(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $child = Student::factory()->inactive()->for($tenant)->for($class, 'schoolClass')->create();
        $child->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/v1/admin/students/{$child->id}/activation", ['active' => true])
            ->assertOk()
            ->assertJsonPath('data.is_activated', true);

        $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/children/{$child->id}/dashboard")
            ->assertOk();
    }

    public function test_a_teacher_cannot_toggle_activation(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacherUser = User::factory()->for($tenant)->create();
        $teacherUser->assignRole('teacher');

        $class = SchoolClass::factory()->for($tenant)->create();
        $child = Student::factory()->inactive()->for($tenant)->for($class, 'schoolClass')->create();

        $this->actingAs($teacherUser, 'sanctum')
            ->patchJson("/api/v1/admin/students/{$child->id}/activation", ['active' => true])
            ->assertForbidden();
    }
}
