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
        if (! Schema::hasColumn('behavior_observations', 'acknowledged_at')) {
            Schema::table('behavior_observations', function (Blueprint $table) {
                $table->timestamp('acknowledged_at')->nullable()->after('visible_to_parent');
            });
        }

        if (! Schema::hasColumn('behavior_observations', 'acknowledged_by_user_id')) {
            Schema::table('behavior_observations', function (Blueprint $table) {
                $table->unsignedBigInteger('acknowledged_by_user_id')->nullable()->after('acknowledged_at');
            });
        }

        $contrainteExiste = collect(Schema::getForeignKeys('behavior_observations'))
            ->contains(fn ($fk) => in_array('acknowledged_by_user_id', $fk['columns']));

        if (! $contrainteExiste) {
            Schema::table('behavior_observations', function (Blueprint $table) {
                $table->foreign('acknowledged_by_user_id')->references('id')->on('users')->nullOnDelete();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('behavior_observations', function (Blueprint $table) {
            $table->dropForeign(['acknowledged_by_user_id']);
            $table->dropColumn(['acknowledged_by_user_id', 'acknowledged_at']);
        });
    }
};
