<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\SchoolClass;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\Tenant;
use App\Models\TimetableSlot;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class TimetableSlotTest extends TestCase
{
    use RefreshDatabase;

    public function test_direction_can_create_a_timetable_slot_but_a_parent_cannot(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $direction = User::factory()->for($tenant)->create();
        $direction->assignRole('direction');

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        $subject = Subject::factory()->for($tenant)->create();
        $teacherUser = User::factory()->for($tenant)->create();
        $teacher = Teacher::factory()->for($tenant)->create(['user_id' => $teacherUser->id]);

        $payload = [
            'school_class_id' => $class->id,
            'subject_id' => $subject->id,
            'teacher_id' => $teacher->id,
            'day_of_week' => 1,
            'start_time' => '08:00',
            'end_time' => '09:00',
        ];

        $this->actingAs($parent, 'sanctum')
            ->postJson('/api/v1/admin/timetable-slots', $payload)
            ->assertForbidden();

        $this->actingAs($direction, 'sanctum')
            ->postJson('/api/v1/admin/timetable-slots', $payload)
            ->assertCreated();
    }

    public function test_anyone_with_timetable_view_can_list_a_classs_schedule(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $class = SchoolClass::factory()->for($tenant)->create();
        TimetableSlot::factory()->for($tenant)->count(3)->create(['school_class_id' => $class->id]);

        $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/admin/timetable-slots?school_class_id={$class->id}")
            ->assertOk()
            ->assertJsonCount(3, 'data');
    }
}
