<?php

namespace Tests\Feature\Api\V1;

use App\Models\Homework;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * Parcours parent (docs/PRODUCT_ARCHITECTURE.md §9 et §12) : le tableau de
 * bord et les devoirs filtrés par échéance ne portent que sur les propres
 * enfants du parent connecté.
 */
class ChildrenControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_parent_only_lists_their_own_children(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $ownChild = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        $ownChild->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $response = $this->actingAs($parent, 'sanctum')
            ->getJson('/api/v1/children')
            ->assertOk();

        $this->assertCount(1, $response->json('data'));
        $this->assertSame($ownChild->id, $response->json('data.0.id'));
    }

    public function test_homeworks_range_filters_are_applied(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $subject = Subject::factory()->for($tenant)->create();
        $teacherUser = User::factory()->for($tenant)->create();
        $teacher = Teacher::factory()->for($tenant)->create(['user_id' => $teacherUser->id]);

        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        $student->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        Homework::factory()->for($tenant)->create([
            'school_class_id' => $class->id, 'subject_id' => $subject->id, 'teacher_id' => $teacher->id,
            'due_date' => today(),
        ]);
        Homework::factory()->for($tenant)->create([
            'school_class_id' => $class->id, 'subject_id' => $subject->id, 'teacher_id' => $teacher->id,
            'due_date' => today()->subWeek(),
        ]);
        Homework::factory()->for($tenant)->create([
            'school_class_id' => $class->id, 'subject_id' => $subject->id, 'teacher_id' => $teacher->id,
            'due_date' => today()->addMonth(),
        ]);

        $today = $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/children/{$student->id}/homeworks?range=today")
            ->assertOk();
        $this->assertCount(1, $today->json('data'));

        $late = $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/children/{$student->id}/homeworks?range=late")
            ->assertOk();
        $this->assertCount(1, $late->json('data'));
    }

    public function test_a_parent_cannot_see_another_childs_dashboard(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $otherChild = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/children/{$otherChild->id}/dashboard")
            ->assertForbidden();
    }

    public function test_grades_are_hidden_when_the_module_is_disabled(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $tenant->subscriptionModules()->create(['module_key' => 'notes', 'is_enabled' => false]);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        $student->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/children/{$student->id}/grades")
            ->assertForbidden();
    }
}
