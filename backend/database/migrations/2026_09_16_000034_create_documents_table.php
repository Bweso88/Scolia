<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->enum('category', ['bulletin', 'circulaire', 'reglement', 'calendrier', 'autre'])->default('autre');
            $table->string('file_path');
            $table->enum('visible_to', ['all', 'school_class', 'student', 'user'])->default('all');
            $table->unsignedBigInteger('target_id')->nullable();
            $table->foreignId('uploaded_by_user_id')->constrained('users');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('documents');
    }
};
