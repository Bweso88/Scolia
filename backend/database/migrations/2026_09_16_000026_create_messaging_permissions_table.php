<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /** Règles école : quels enseignants sont joignables directement par les parents. */
    public function up(): void
    {
        Schema::create('messaging_permissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('teacher_id')->unique()->constrained()->cascadeOnDelete();
            $table->boolean('can_be_contacted_directly')->default(false);
            $table->boolean('requires_admin_relay')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('messaging_permissions');
    }
};
