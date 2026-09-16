<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Ciblage polymorphique simple (colonnes explicites, pas de relation
     * morphTo Eloquent) pour rester lisible en SQL direct — voir §8.
     */
    public function up(): void
    {
        Schema::create('announcement_targets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('announcement_id')->constrained()->cascadeOnDelete();
            $table->enum('target_type', ['all', 'school_class', 'user_group', 'user']);
            $table->unsignedBigInteger('target_id')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('announcement_targets');
    }
};
