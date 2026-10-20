<?php

namespace Tests\Feature\Api\V1\Admin;

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
 * Le devoir publié doit générer un statut "pending" pour chaque élève actif
 * de la classe (docs/PRODUCT_ARCHITECTURE.md §7, table homework_status) :
 * c'est ce qui alimente les vues "à faire" côté parent.
 */
class HomeworkPublishingTest extends TestCase
{
    use RefreshDatabase;

    public function test_publishing_a_homework_creates_a_status_per_active_student(): void
    {
        $tenant = Tenant::factory()->create();
        $class = SchoolClass::factory()->for($tenant)->create();
        $subject = Subject::factory()->for($tenant)->create();

        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);
        $teacherUser = User::factory()->for($tenant)->create();
        $teacherUser->assignRole('teacher');
        $teacher = Teacher::factory()->for($tenant)->create(['user_id' => $teacherUser->id]);

        Student::factory()->for($tenant)->for($class, 'schoolClass')->count(3)->create(['status' => 'active']);
        Student::factory()->for($tenant)->for($class, 'schoolClass')->create(['status' => 'transferred']);

        $response = $this->actingAs($teacherUser, 'sanctum')
            ->postJson('/api/v1/admin/homeworks', [
                'school_class_id' => $class->id,
                'subject_id' => $subject->id,
                'teacher_id' => $teacher->id,
                'title' => 'Exercices 1 à 5 page 42',
                'due_date' => now()->addDays(3)->toDateString(),
            ])
            ->assertCreated();

        $homeworkId = $response->json('data.id');

        $this->assertDatabaseCount('homework_status', 3);
        $this->assertDatabaseHas('homework_status', [
            'homework_id' => $homeworkId,
            'status' => 'pending',
        ]);
    }

    public function test_a_teacher_cannot_update_another_teachers_homework(): void
    {
        $tenant = Tenant::factory()->create();

        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);
        $author = User::factory()->for($tenant)->create();
        $author->assignRole('teacher');
        $authorTeacher = Teacher::factory()->for($tenant)->create(['user_id' => $author->id]);

        $intruder = User::factory()->for($tenant)->create();
        $intruder->assignRole('teacher');

        $homework = Homework::factory()->for($tenant)->create(['teacher_id' => $authorTeacher->id]);

        $this->actingAs($intruder, 'sanctum')
            ->patchJson("/api/v1/admin/homeworks/{$homework->id}", ['title' => 'Piraté'])
            ->assertForbidden();
    }
}
