<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Jonction avec Talenda (logiciel de gestion de l'école, référence pour
 * les élèves, classes, matières, enseignants et responsables) : chaque
 * fiche synchronisée garde l'uuid Talenda dont elle provient.
 *
 * L'email devient facultatif : un parent connu de Talenda par son seul
 * numéro de téléphone doit pouvoir exister dans Scolia.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('email')->nullable()->change();
            $table->uuid('talenda_account_uuid')->nullable();
            $table->uuid('talenda_guardian_uuid')->nullable();
            $table->unique(['tenant_id', 'talenda_account_uuid']);
            $table->unique(['tenant_id', 'talenda_guardian_uuid']);
            $table->index('phone');
        });

        foreach (['school_years', 'subjects', 'school_classes', 'teachers', 'students'] as $tableName) {
            Schema::table($tableName, function (Blueprint $table) {
                $table->uuid('talenda_uuid')->nullable();
                $table->unique(['tenant_id', 'talenda_uuid']);
            });
        }

        Schema::table('tenant_settings', function (Blueprint $table) {
            $table->string('talenda_url')->nullable();
            $table->text('talenda_token')->nullable();
            $table->timestamp('talenda_synced_at')->nullable();
            $table->text('talenda_sync_error')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('tenant_settings', function (Blueprint $table) {
            $table->dropColumn(['talenda_url', 'talenda_token', 'talenda_synced_at', 'talenda_sync_error']);
        });

        foreach (['school_years', 'subjects', 'school_classes', 'teachers', 'students'] as $tableName) {
            Schema::table($tableName, function (Blueprint $table) use ($tableName) {
                $table->dropUnique("{$tableName}_tenant_id_talenda_uuid_unique");
                $table->dropColumn('talenda_uuid');
            });
        }

        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['tenant_id', 'talenda_account_uuid']);
            $table->dropUnique(['tenant_id', 'talenda_guardian_uuid']);
            $table->dropIndex(['phone']);
            $table->dropColumn(['talenda_account_uuid', 'talenda_guardian_uuid']);
        });
    }
};
