<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('behavior_observations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('student_id')->constrained()->cascadeOnDelete();
            $table->foreignId('author_user_id')->constrained('users');
            $table->enum('category', ['positive', 'discipline', 'participation', 'incident', 'note_generale']);
            $table->string('title');
            $table->text('description')->nullable();
            $table->dateTime('occurred_at');
            $table->boolean('visible_to_parent')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('behavior_observations');
    }
};
