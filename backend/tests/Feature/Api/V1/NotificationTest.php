<?php

namespace Tests\Feature\Api\V1;

use App\Models\AttendanceRecord;
use App\Models\GradingPeriod;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\Tenant;
use App\Models\User;
use App\Notifications\AbsenceRecordedNotification;
use App\Notifications\Channels\FcmChannel;
use App\Notifications\NewBehaviorObservationNotification;
use App\Notifications\NewGradeNotification;
use App\Notifications\NewHomeworkNotification;
use App\Support\Tenancy\TenantContext;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * docs/PRODUCT_ARCHITECTURE.md §16 : chaque catégorie déclenche une
 * notification dédiée vers les parents concernés, filtrable par préférence.
 */
class NotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_publishing_a_homework_notifies_the_students_guardians(): void
    {
        Notification::fake();

        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacherUser = User::factory()->for($tenant)->create();
        $teacherUser->assignRole('teacher');
        $teacher = Teacher::factory()->for($tenant)->create(['user_id' => $teacherUser->id]);

        $class = SchoolClass::factory()->for($tenant)->create();
        $subject = Subject::factory()->for($tenant)->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');
        $student->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $this->actingAs($teacherUser, 'sanctum')
            ->postJson('/api/v1/admin/homeworks', [
                'school_class_id' => $class->id,
                'subject_id' => $subject->id,
                'teacher_id' => $teacher->id,
                'title' => 'Exercices de conjugaison',
                'due_date' => now()->addDays(2)->toDateString(),
            ])
            ->assertCreated();

        Notification::assertSentTo($parent, NewHomeworkNotification::class);
    }

    public function test_recording_an_absence_notifies_the_students_guardian(): void
    {
        Notification::fake();

        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        $class = SchoolClass::factory()->for($tenant)->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');
        $student->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/attendance-records', [
                'student_id' => $student->id,
                'type' => 'absence',
                'date' => today()->toDateString(),
            ])
            ->assertCreated();

        Notification::assertSentTo($parent, AbsenceRecordedNotification::class);
    }

    public function test_adding_a_behavior_observation_notifies_the_students_guardian(): void
    {
        Notification::fake();

        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacherUser = User::factory()->for($tenant)->create();
        $teacherUser->assignRole('teacher');

        $class = SchoolClass::factory()->for($tenant)->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');
        $student->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $this->actingAs($teacherUser, 'sanctum')
            ->postJson('/api/v1/admin/behavior-observations', [
                'student_id' => $student->id,
                'category' => 'positive',
                'title' => 'Très bonne participation',
            ])
            ->assertCreated();

        Notification::assertSentTo($parent, NewBehaviorObservationNotification::class);
    }

    public function test_a_behavior_observation_hidden_from_parents_does_not_notify_them(): void
    {
        Notification::fake();

        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacherUser = User::factory()->for($tenant)->create();
        $teacherUser->assignRole('teacher');

        $class = SchoolClass::factory()->for($tenant)->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');
        $student->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $this->actingAs($teacherUser, 'sanctum')
            ->postJson('/api/v1/admin/behavior-observations', [
                'student_id' => $student->id,
                'category' => 'discipline',
                'title' => 'Note interne',
                'visible_to_parent' => false,
            ])
            ->assertCreated();

        Notification::assertNotSentTo($parent, NewBehaviorObservationNotification::class);
    }

    public function test_entering_a_grade_notifies_the_students_guardian(): void
    {
        Notification::fake();

        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        $class = SchoolClass::factory()->for($tenant)->create();
        $subject = Subject::factory()->for($tenant)->create();
        $gradingPeriod = GradingPeriod::factory()->for($tenant)->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');
        $student->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/grades', [
                'student_id' => $student->id,
                'subject_id' => $subject->id,
                'grading_period_id' => $gradingPeriod->id,
                'score' => 15,
                'max_score' => 20,
            ])
            ->assertCreated();

        Notification::assertSentTo($parent, NewGradeNotification::class);
    }

    public function test_disabling_push_for_a_category_keeps_the_database_channel_only(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        // Hors requête HTTP, TenantContext n'est renseigné par aucun
        // middleware : on le fixe explicitement, comme le ferait
        // ResolveTenant en production.
        app(TenantContext::class)->set($tenant);
        $parent->notificationPreferences()->create([
            'category' => 'absence', 'channel' => 'push', 'is_enabled' => false,
        ]);

        $record = AttendanceRecord::factory()->for($tenant)->create();

        $channels = (new AbsenceRecordedNotification($record))->via($parent);

        $this->assertContains('database', $channels);
        $this->assertNotContains(FcmChannel::class, $channels);
    }

    public function test_a_user_can_register_a_device_token_and_update_notification_preferences(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $this->actingAs($parent, 'sanctum')
            ->postJson('/api/v1/devices', ['fcm_token' => 'token-abc', 'platform' => 'android'])
            ->assertCreated();

        $this->assertDatabaseHas('device_tokens', ['user_id' => $parent->id, 'fcm_token' => 'token-abc']);

        $this->actingAs($parent, 'sanctum')
            ->patchJson('/api/v1/notification-preferences', [
                'preferences' => [
                    ['category' => 'devoir', 'channel' => 'push', 'is_enabled' => false],
                ],
            ])
            ->assertOk();

        $this->assertDatabaseHas('notification_preferences', [
            'user_id' => $parent->id, 'category' => 'devoir', 'channel' => 'push', 'is_enabled' => false,
        ]);
    }

    public function test_a_user_can_list_and_mark_their_notifications_as_read(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $record = AttendanceRecord::factory()->for($tenant)->create();
        $parent->notify(new AbsenceRecordedNotification($record));

        $response = $this->actingAs($parent, 'sanctum')
            ->getJson('/api/v1/notifications')
            ->assertOk();

        $this->assertSame(1, $response->json('unread_count'));
        $notificationId = $response->json('data.data.0.id');

        $this->actingAs($parent, 'sanctum')
            ->patchJson("/api/v1/notifications/{$notificationId}/read")
            ->assertOk();

        $this->assertDatabaseMissing('notifications', ['id' => $notificationId, 'read_at' => null]);
    }
}
