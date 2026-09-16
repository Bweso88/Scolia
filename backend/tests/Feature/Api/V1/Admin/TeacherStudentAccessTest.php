<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeacherAssignment;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * Régression : un enseignant (student.view sans student.manage) doit
 * pouvoir consulter les élèves de son école, pas seulement ses propres
 * enfants — le filtre "parent" ne doit s'appliquer qu'au rôle parent.
 */
class TeacherStudentAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_teacher_can_list_and_view_students_of_their_school(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacherUser = User::factory()->for($tenant)->create();
        $teacherUser->assignRole('teacher');
        Teacher::factory()->for($tenant)->create(['user_id' => $teacherUser->id]);

        $class = SchoolClass::factory()->for($tenant)->create();
        $student = Student::factory()->for($tenant)->for($class, 'schoolClass')->create();

        $index = $this->actingAs($teacherUser, 'sanctum')
            ->getJson('/api/v1/admin/students')
            ->assertOk();
        $this->assertCount(1, $index->json('data'));

        $this->actingAs($teacherUser, 'sanctum')
            ->getJson("/api/v1/admin/students/{$student->id}")
            ->assertOk();
    }

    public function test_login_response_includes_the_users_role_and_assigned_classes(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacherUser = User::factory()->for($tenant)->create(['password' => Hash::make('secret')]);
        $teacherUser->assignRole('teacher');
        $class = SchoolClass::factory()->for($tenant)->create();
        $teacher = Teacher::factory()->for($tenant)->create(['user_id' => $teacherUser->id]);
        TeacherAssignment::factory()->for($tenant)->create([
            'teacher_id' => $teacher->id,
            'school_class_id' => $class->id,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => $teacherUser->email,
            'password' => 'secret',
        ])->assertOk();

        $this->assertSame(['teacher'], $response->json('user.roles'));
        $this->assertCount(1, $response->json('user.classes'));
    }
}
