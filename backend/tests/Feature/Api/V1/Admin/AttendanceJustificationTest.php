<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\AttendanceRecord;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * docs/PRODUCT_ARCHITECTURE.md §6 module Absences : le parent justifie une
 * absence, l'administration approuve ou rejette le justificatif.
 */
class AttendanceJustificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_parent_can_justify_their_childs_absence_but_not_someone_elses(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $ownChild = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        $otherChild = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        $ownChild->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $ownAbsence = AttendanceRecord::factory()->for($tenant)->create(['student_id' => $ownChild->id, 'type' => 'absence']);
        $otherAbsence = AttendanceRecord::factory()->for($tenant)->create(['student_id' => $otherChild->id, 'type' => 'absence']);

        $this->actingAs($parent, 'sanctum')
            ->postJson("/api/v1/admin/attendance-records/{$ownAbsence->id}/justify", ['explanation' => 'Rendez-vous médical'])
            ->assertCreated();

        $this->actingAs($parent, 'sanctum')
            ->postJson("/api/v1/admin/attendance-records/{$otherAbsence->id}/justify", ['explanation' => 'Tentative'])
            ->assertForbidden();

        $this->assertDatabaseHas('attendance_justifications', [
            'attendance_record_id' => $ownAbsence->id,
            'status' => 'pending',
        ]);
    }

    public function test_a_teacher_cannot_review_a_justification_only_administration_can(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $teacher = User::factory()->for($tenant)->create();
        $teacher->assignRole('teacher');

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        $class = SchoolClass::factory()->for($tenant)->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        $student->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $absence = AttendanceRecord::factory()->for($tenant)->create(['student_id' => $student->id]);

        $this->actingAs($parent, 'sanctum')
            ->postJson("/api/v1/admin/attendance-records/{$absence->id}/justify", ['explanation' => 'Maladie'])
            ->assertCreated();

        $this->actingAs($teacher, 'sanctum')
            ->patchJson("/api/v1/admin/attendance-records/{$absence->id}/justification", ['status' => 'approved'])
            ->assertForbidden();

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/v1/admin/attendance-records/{$absence->id}/justification", ['status' => 'approved'])
            ->assertOk();

        $this->assertDatabaseHas('attendance_justifications', [
            'attendance_record_id' => $absence->id,
            'status' => 'approved',
        ]);
    }
}
