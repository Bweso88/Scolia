<?php

namespace Database\Seeders;

use App\Models\Announcement;
use App\Models\AnnouncementTarget;
use App\Models\AttendanceRecord;
use App\Models\BehaviorObservation;
use App\Models\Homework;
use App\Models\Plan;
use App\Models\SchoolClass;
use App\Models\SchoolYear;
use App\Models\Student;
use App\Models\StudentGuardian;
use App\Models\Subject;
use App\Models\Subscription;
use App\Models\Teacher;
use App\Models\TeacherAssignment;
use App\Models\Tenant;
use App\Models\TimetableSlot;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\PermissionRegistrar;

/**
 * École de démonstration complète pour tester le parcours enseignant ↔
 * parent en conditions réelles, sur deux téléphones : un professeur
 * (Android) et un parent avec deux enfants (iPhone), dont un seul
 * "activé" — pour tester la simulation d'activation payante par enfant
 * (docs/PRODUCT_ARCHITECTURE.md §18).
 *
 * Identifiants (mot de passe identique) :
 *   - direction@lespalmiers.test  (direction / back-office)
 *   - prof@lespalmiers.test       (enseignant, classe CM2)
 *   - parent@lespalmiers.test     (parent, enfants Aïcha [activée] et Noah [non activé])
 *   Mot de passe : demo1234
 */
class DemoSeeder extends Seeder
{
    private const PASSWORD = 'demo1234';

    public function run(): void
    {
        $tenant = Tenant::factory()->create([
            'name' => 'École Les Palmiers',
            'slug' => 'les-palmiers',
        ]);

        app(PermissionRegistrar::class)->setPermissionsTeamId($tenant->id);

        $schoolYear = SchoolYear::factory()->for($tenant)->create();

        $tenant->settings()->create([
            'display_name' => 'École Les Palmiers',
            'primary_color' => '#0D1B3E',
            'secondary_color' => '#F5A623',
            'phone' => '+242 06 000 00 00',
            'email' => 'contact@lespalmiers.test',
            'current_school_year_id' => $schoolYear->id,
        ]);

        $plan = Plan::firstOrCreate(
            ['code' => 'starter'],
            [
                'name' => 'Starter',
                'max_students' => 300,
                'price_amount' => 500000,
                'price_currency' => 'XOF',
                'billing_period' => 'yearly',
                'is_active' => true,
            ]
        );

        Subscription::create([
            'tenant_id' => $tenant->id,
            'plan_id' => $plan->id,
            'status' => 'active',
            'current_period_start' => now()->startOfYear(),
            'current_period_end' => now()->addYear(),
            'students_count_cache' => 2,
        ]);

        $class = SchoolClass::factory()->for($tenant)->for($schoolYear, 'schoolYear')->create(['name' => 'CM2']);

        $math = Subject::factory()->for($tenant)->create(['name' => 'Mathématiques']);
        $french = Subject::factory()->for($tenant)->create(['name' => 'Français']);

        $directionUser = User::factory()->for($tenant)->create([
            'name' => 'Aminata Diallo',
            'email' => 'direction@lespalmiers.test',
            'password' => Hash::make(self::PASSWORD),
        ]);
        $directionUser->assignRole('school_admin');

        $teacherUser = User::factory()->for($tenant)->create([
            'name' => 'Jean Koffi',
            'email' => 'prof@lespalmiers.test',
            'password' => Hash::make(self::PASSWORD),
        ]);
        $teacherUser->assignRole('teacher');

        $teacher = Teacher::factory()->for($tenant)->create(['user_id' => $teacherUser->id]);

        TeacherAssignment::create([
            'tenant_id' => $tenant->id,
            'teacher_id' => $teacher->id,
            'school_class_id' => $class->id,
            'subject_id' => $math->id,
        ]);

        $class->update(['homeroom_teacher_id' => $teacher->id]);

        $parentUser = User::factory()->for($tenant)->create([
            'name' => 'Mariam Traoré',
            'email' => 'parent@lespalmiers.test',
            'password' => Hash::make(self::PASSWORD),
        ]);
        $parentUser->assignRole('parent');

        $activeChild = Student::factory()->for($tenant)->for($class, 'schoolClass')->create([
            'first_name' => 'Aïcha',
            'last_name' => 'Traoré',
            'gender' => 'f',
            'activated_at' => now(),
        ]);
        StudentGuardian::create([
            'tenant_id' => $tenant->id,
            'student_id' => $activeChild->id,
            'user_id' => $parentUser->id,
            'relationship_type' => 'mère',
            'is_primary_contact' => true,
        ]);

        $inactiveChild = Student::factory()->for($tenant)->for($class, 'schoolClass')->create([
            'first_name' => 'Noah',
            'last_name' => 'Traoré',
            'gender' => 'm',
            'activated_at' => null,
        ]);
        StudentGuardian::create([
            'tenant_id' => $tenant->id,
            'student_id' => $inactiveChild->id,
            'user_id' => $parentUser->id,
            'relationship_type' => 'mère',
            'is_primary_contact' => true,
        ]);

        Homework::factory()->for($tenant)->create([
            'school_class_id' => $class->id,
            'subject_id' => $math->id,
            'teacher_id' => $teacher->id,
            'title' => 'Exercices 4 à 8 page 32',
            'instructions' => 'Tables de multiplication de 6 à 9.',
            'due_date' => today()->addDays(2),
        ]);

        Homework::factory()->for($tenant)->create([
            'school_class_id' => $class->id,
            'subject_id' => $french->id,
            'teacher_id' => $teacher->id,
            'title' => 'Lecture chapitre 3',
            'instructions' => 'Résumé en 5 lignes pour vendredi.',
            'due_date' => today()->addWeek(),
        ]);

        BehaviorObservation::factory()->for($tenant)->create([
            'student_id' => $activeChild->id,
            'author_user_id' => $teacherUser->id,
            'category' => 'positive',
            'title' => 'Très bonne participation en classe',
            'description' => "Aïcha a aidé un camarade en difficulté pendant l'exercice de mathématiques.",
        ]);

        AttendanceRecord::factory()->for($tenant)->create([
            'student_id' => $activeChild->id,
            'type' => 'retard',
            'date' => today(),
            'recorded_by_user_id' => $teacherUser->id,
        ]);

        $announcement = Announcement::factory()->for($tenant)->create([
            'author_user_id' => $directionUser->id,
            'title' => 'Réunion de rentrée',
            'body' => "La réunion de rentrée aura lieu samedi à 9h dans la cour de l'école.",
        ]);
        AnnouncementTarget::create([
            'tenant_id' => $tenant->id,
            'announcement_id' => $announcement->id,
            'target_type' => 'all',
        ]);

        TimetableSlot::factory()->for($tenant)->create([
            'school_class_id' => $class->id,
            'subject_id' => $math->id,
            'teacher_id' => $teacher->id,
            'day_of_week' => now()->dayOfWeekIso,
            'start_time' => '08:00',
            'end_time' => '09:00',
        ]);

        $this->command?->info(
            'École de démo créée — direction@lespalmiers.test / prof@lespalmiers.test / parent@lespalmiers.test (mot de passe : '.self::PASSWORD.')'
        );
    }
}
