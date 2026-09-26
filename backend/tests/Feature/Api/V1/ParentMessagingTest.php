<?php

namespace Tests\Feature\Api\V1;

use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherAssignment;
use App\Models\Tenant;
use App\Models\User;
use App\Support\Tenancy\TenantContext;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * Espace parent → prof/direction (docs/PRODUCT_ARCHITECTURE.md §7) : un
 * parent doit toujours pouvoir joindre la direction, uniquement un
 * enseignant autorisé, et jamais après l'heure limite de l'école.
 */
class ParentMessagingTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_messaging_contacts_lists_the_classs_teachers_and_the_direction(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $admin = User::factory()->for($tenant)->create(['name' => 'Aminata Diallo']);
        $admin->assignRole('school_admin');

        $teacherUser = User::factory()->for($tenant)->create(['name' => 'Jean Koffi']);
        $teacherUser->assignRole('teacher');
        $teacher = Teacher::factory()->for($tenant)->create(['user_id' => $teacherUser->id]);

        $class = SchoolClass::factory()->for($tenant)->create();
        $subject = Subject::factory()->for($tenant)->create();
        app(TenantContext::class)->set($tenant);
        TeacherAssignment::create([
            'teacher_id' => $teacher->id,
            'school_class_id' => $class->id,
            'subject_id' => $subject->id,
        ]);

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        $student->guardians()->attach($parent->id, ['tenant_id' => $tenant->id, 'relationship_type' => 'parent']);

        $response = $this->actingAs($parent, 'sanctum')
            ->getJson("/api/v1/children/{$student->id}/messaging-contacts")
            ->assertOk();

        $response->assertJsonPath('teachers.0.name', 'Jean Koffi');
        $response->assertJsonPath('teachers.0.contactable', false);
        $response->assertJsonPath('direction.0.name', 'Aminata Diallo');
    }

    public function test_a_parent_can_always_message_the_direction(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $this->actingAs($parent, 'sanctum')
            ->postJson('/api/v1/admin/conversations', [
                'participant_user_id' => $admin->id,
                'subject' => 'Question sur la rentrée',
                'body' => "Bonjour, j'aurais une question sur les horaires.",
            ])
            ->assertCreated();
    }

    public function test_a_parent_cannot_start_a_conversation_past_the_messaging_cutoff(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);
        $tenant->settings()->create(['display_name' => $tenant->name, 'messaging_cutoff_time' => '18:00:00']);

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        Carbon::setTestNow(Carbon::parse('2026-09-26 19:30:00'));

        $this->actingAs($parent, 'sanctum')
            ->postJson('/api/v1/admin/conversations', [
                'participant_user_id' => $admin->id,
                'body' => 'Bonsoir, une question urgente ?',
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('body');
    }

    public function test_staff_can_reply_past_the_messaging_cutoff(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);
        $tenant->settings()->create(['display_name' => $tenant->name, 'messaging_cutoff_time' => '18:00:00']);

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $conversation = $this->actingAs($parent, 'sanctum')
            ->postJson('/api/v1/admin/conversations', [
                'participant_user_id' => $admin->id,
                'body' => 'Bonjour, une question.',
            ])
            ->assertCreated()
            ->json('data.id');

        Carbon::setTestNow(Carbon::parse('2026-09-26 21:00:00'));

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/conversations/{$conversation}/messages", [
                'body' => 'Bonsoir, je réponds ce soir.',
            ])
            ->assertCreated();
    }

    public function test_a_parent_cannot_reply_past_the_messaging_cutoff(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);
        $tenant->settings()->create(['display_name' => $tenant->name, 'messaging_cutoff_time' => '18:00:00']);

        $admin = User::factory()->for($tenant)->create();
        $admin->assignRole('school_admin');

        $parent = User::factory()->for($tenant)->create();
        $parent->assignRole('parent');

        $conversation = $this->actingAs($parent, 'sanctum')
            ->postJson('/api/v1/admin/conversations', [
                'participant_user_id' => $admin->id,
                'body' => 'Bonjour, une question.',
            ])
            ->assertCreated()
            ->json('data.id');

        Carbon::setTestNow(Carbon::parse('2026-09-26 21:00:00'));

        $this->actingAs($parent, 'sanctum')
            ->postJson("/api/v1/admin/conversations/{$conversation}/messages", [
                'body' => 'Une dernière chose ce soir...',
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('body');
    }
}
