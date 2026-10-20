<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\SchoolClass;
use App\Models\SchoolYear;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * "Ajouter une école = une ligne dans tenants, aucune modification de
 * code" (docs/PRODUCT_ARCHITECTURE.md §15) suppose que la direction
 * puisse ensuite tout créer elle-même : matières, classes, professeurs,
 * élèves, parents — testé ici pour l'API JSON (voir aussi le panel
 * Filament, testé dans FilamentAdminPanelTest, qui couvre le même
 * besoin depuis un navigateur).
 */
class SchoolManagementTest extends TestCase
{
    use RefreshDatabase;

    private function direction(Tenant $tenant): User
    {
        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        return $admin;
    }

    public function test_direction_can_manage_subjects(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);
        $admin = $this->direction($tenant);

        $id = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/subjects', ['name' => 'Mathématiques'])
            ->assertCreated()
            ->json('data.id');

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/v1/admin/subjects/{$id}", ['name' => 'Maths'])
            ->assertOk()
            ->assertJsonPath('data.name', 'Maths');

        $this->actingAs($admin, 'sanctum')
            ->deleteJson("/api/v1/admin/subjects/{$id}")
            ->assertNoContent();
    }

    public function test_a_teacher_cannot_manage_subjects(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacher = User::factory()->for($tenant)->create();
        $teacher->assignRole('teacher');

        $this->actingAs($teacher, 'sanctum')
            ->postJson('/api/v1/admin/subjects', ['name' => 'Mathématiques'])
            ->assertForbidden();
    }

    public function test_direction_can_manage_school_classes(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);
        $admin = $this->direction($tenant);

        $schoolYear = SchoolYear::factory()->for($tenant)->create();

        $classId = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/school-classes', [
                'name' => 'CM2',
                'school_year_id' => $schoolYear->id,
            ])
            ->assertCreated()
            ->json('data.id');

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/school-classes')
            ->assertOk()
            ->assertJsonFragment(['name' => 'CM2']);

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/v1/admin/school-classes/{$classId}", ['level' => 'Primaire'])
            ->assertOk()
            ->assertJsonPath('data.level', 'Primaire');
    }

    public function test_direction_can_create_a_teacher_with_a_new_user_account_and_assignments(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);
        $admin = $this->direction($tenant);

        $schoolYear = SchoolYear::factory()->for($tenant)->create();
        $class = SchoolClass::factory()->for($tenant)->for($schoolYear, 'schoolYear')->create();
        $subject = Subject::factory()->for($tenant)->create();

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/teachers', [
                'name' => 'Jean Koffi',
                'email' => 'jean.koffi@lespalmiers.test',
                'password' => 'motdepasse123',
                'employee_number' => 'ENS-001',
                'assignments' => [
                    ['school_class_id' => $class->id, 'subject_id' => $subject->id],
                ],
            ])
            ->assertCreated();

        $response->assertJsonPath('data.name', 'Jean Koffi');
        $response->assertJsonCount(1, 'data.assignments');

        $this->assertDatabaseHas('users', ['email' => 'jean.koffi@lespalmiers.test']);
        $newTeacherUser = User::where('email', 'jean.koffi@lespalmiers.test')->first();
        $this->assertTrue($newTeacherUser->hasRole('teacher'));
    }

    public function test_direction_can_create_a_teacher_from_an_existing_user_account(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);
        $admin = $this->direction($tenant);

        $existingUser = User::factory()->for($tenant)->create();

        $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/teachers', ['user_id' => $existingUser->id])
            ->assertCreated();

        $this->assertTrue($existingUser->fresh()->hasRole('teacher'));
    }

    public function test_a_parent_cannot_create_a_teacher(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $this->actingAs($parent, 'sanctum')
            ->postJson('/api/v1/admin/teachers', [
                'name' => 'Jean Koffi',
                'email' => 'jean.koffi@lespalmiers.test',
                'password' => 'motdepasse123',
            ])
            ->assertForbidden();
    }

    public function test_direction_can_link_a_new_parent_to_a_student(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);
        $admin = $this->direction($tenant);

        $schoolYear = SchoolYear::factory()->for($tenant)->create();
        $class = SchoolClass::factory()->for($tenant)->for($schoolYear, 'schoolYear')->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/students/{$student->id}/guardians", [
                'name' => 'Mariam Traoré',
                'email' => 'mariam.traore@lespalmiers.test',
                'password' => 'motdepasse123',
                'relationship_type' => 'mère',
                'is_primary_contact' => true,
            ])
            ->assertCreated();

        $response->assertJsonPath('data.name', 'Mariam Traoré');
        $response->assertJsonPath('data.is_primary_contact', true);

        $newParent = User::where('email', 'mariam.traore@lespalmiers.test')->first();
        $this->assertTrue($newParent->hasRole('parent'));
        $this->assertTrue($student->guardians()->whereKey($newParent->id)->exists());
    }

    public function test_direction_can_link_an_existing_parent_to_another_student(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);
        $admin = $this->direction($tenant);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $schoolYear = SchoolYear::factory()->for($tenant)->create();
        $class = SchoolClass::factory()->for($tenant)->for($schoolYear, 'schoolYear')->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/students/{$student->id}/guardians", [
                'user_id' => $parent->id,
                'relationship_type' => 'père',
            ])
            ->assertCreated();

        $this->assertTrue($student->guardians()->whereKey($parent->id)->exists());
    }

    public function test_a_teacher_cannot_link_a_parent_to_a_student(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacher = User::factory()->for($tenant)->create();
        $teacher->assignRole('teacher');

        $schoolYear = SchoolYear::factory()->for($tenant)->create();
        $class = SchoolClass::factory()->for($tenant)->for($schoolYear, 'schoolYear')->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        $this->actingAs($teacher, 'sanctum')
            ->postJson("/api/v1/admin/students/{$student->id}/guardians", [
                'name' => 'Mariam Traoré',
                'email' => 'mariam.traore@lespalmiers.test',
                'password' => 'motdepasse123',
                'relationship_type' => 'mère',
            ])
            ->assertForbidden();
    }
}
