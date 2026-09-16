<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /** Module Notes/bulletins — structure prête dès le MVP, activable par école. */
    public function up(): void
    {
        Schema::create('grading_periods', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('school_year_id')->constrained();
            $table->string('label');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('grading_periods');
    }
};
