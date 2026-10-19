<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Accusé de lecture : le représentant légal (parent) confirme avoir lu
     * une observation (docs/PRODUCT_ARCHITECTURE.md — écran "Suivi").
     */
    public function up(): void
    {
        Schema::table('behavior_observations', function (Blueprint $table) {
            $table->timestamp('acknowledged_at')->nullable()->after('visible_to_parent');
            $table->foreignId('acknowledged_by_user_id')->nullable()->after('acknowledged_at')->constrained('users')->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('behavior_observations', function (Blueprint $table) {
            $table->dropConstrainedForeignId('acknowledged_by_user_id');
            $table->dropColumn('acknowledged_at');
        });
    }
};
