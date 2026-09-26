<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\Grade;
use App\Models\GradingPeriod;
use App\Models\SchoolClass;
use App\Models\SchoolYear;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class GradeTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_teacher_can_enter_a_grade_but_a_parent_cannot(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacher = User::factory()->for($tenant)->create();
        $teacher->assignRole('teacher');

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        $subject = Subject::factory()->for($tenant)->create();
        $schoolYear = SchoolYear::factory()->for($tenant)->create();
        $period = GradingPeriod::factory()->for($tenant)->create(['school_year_id' => $schoolYear->id]);

        $payload = [
            'student_id' => $student->id,
            'subject_id' => $subject->id,
            'grading_period_id' => $period->id,
            'score' => 15.5,
        ];

        $this->actingAs($parent, 'sanctum')
            ->postJson('/api/v1/admin/grades', $payload)
            ->assertForbidden();

        $this->actingAs($teacher, 'sanctum')
            ->postJson('/api/v1/admin/grades', $payload)
            ->assertCreated();

        $this->assertDatabaseHas('grades', ['student_id' => $student->id, 'score' => 15.5]);
    }

    public function test_a_parent_sees_their_childs_grades_only_when_the_module_is_enabled(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        $student->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        Grade::factory()->for($tenant)->create(['student_id' => $student->id]);

        $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/children/{$student->id}/grades")
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }
}
