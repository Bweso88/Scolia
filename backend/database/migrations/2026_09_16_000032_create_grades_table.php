<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('grades', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('student_id')->constrained()->cascadeOnDelete();
            $table->foreignId('subject_id')->constrained();
            $table->foreignId('grading_period_id')->constrained();
            $table->decimal('score', 5, 2);
            $table->decimal('max_score', 5, 2)->default(20);
            $table->decimal('coefficient', 4, 2)->default(1);
            $table->string('comment')->nullable();
            $table->foreignId('entered_by_user_id')->constrained('users');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('grades');
    }
};
