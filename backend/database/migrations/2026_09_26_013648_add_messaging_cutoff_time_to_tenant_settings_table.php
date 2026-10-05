<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('tenant_settings', function (Blueprint $table) {
            // Heure limite au-delà de laquelle un parent ne peut plus
            // initier de nouveau message vers un professeur/la direction
            // (les réponses du personnel restent toujours possibles).
            $table->time('messaging_cutoff_time')->nullable()->default('18:00:00');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tenant_settings', function (Blueprint $table) {
            $table->dropColumn('messaging_cutoff_time');
        });
    }
};
