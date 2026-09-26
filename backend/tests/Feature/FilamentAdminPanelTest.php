<?php

namespace Tests\Feature;

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
 * Smoke tests du panel /admin (Filament) : vérifie que la direction peut
 * accéder aux Resources et qu'un rôle non autorisé (ex. professeur) en est
 * exclu (voir App\Models\User::canAccessPanel).
 */
class FilamentAdminPanelTest extends TestCase
{
    use RefreshDatabase;

    public function test_school_admin_can_access_the_panel_and_its_resources(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $admin = User::factory()->for($tenant)->create()->refresh();
        $admin->assignRole('school_admin');

        $subject = Subject::factory()->for($tenant)->create();
        $class = SchoolClass::factory()->for($tenant)->create();
        Student::factory()->for($tenant)->for($class, 'schoolClass')->create();
        $teacherUser = User::factory()->for($tenant)->create();
        $teacherUser->assignRole('teacher');
        Teacher::factory()->for($tenant)->create(['user_id' => $teacherUser->id]);

        $this->actingAs($admin)->get('/admin')->assertOk();
        $this->actingAs($admin)->get('/admin/subjects')->assertOk();
        $this->actingAs($admin)->get('/admin/subjects/create')->assertOk();
        $this->actingAs($admin)->get('/admin/school-classes')->assertOk();
        $this->actingAs($admin)->get('/admin/school-classes/create')->assertOk();
        $this->actingAs($admin)->get('/admin/teachers')->assertOk();
        $this->actingAs($admin)->get('/admin/teachers/create')->assertOk();
        $this->actingAs($admin)->get('/admin/students')->assertOk();
        $this->actingAs($admin)->get('/admin/students/create')->assertOk();

        $student = Student::first();
        $this->actingAs($admin)->get("/admin/students/{$student->id}/edit")->assertOk();

        // Sanity check sur les données de test elles-mêmes.
        $this->assertNotNull($subject);
    }

    public function test_a_teacher_cannot_access_the_panel(): void
    {
        $tenant = Tenant::factory()->create();
        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $teacherUser = User::factory()->for($tenant)->create();
        $teacherUser->assignRole('teacher');

        $this->actingAs($teacherUser)->get('/admin')->assertForbidden();
    }
}
