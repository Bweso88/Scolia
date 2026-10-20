<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Permet de rattacher une note au devoir qu'elle évalue (facultatif :
     * une note peut toujours être saisie librement, sans devoir associé).
     *
     * Colonne et contrainte ajoutées séparément et chacune conditionnelle :
     * un premier déploiement a laissé la colonne en place mais pas la
     * contrainte (constrained() sans argument devine la table "homework"
     * au singulier — "homework" est invariable en anglais — alors que la
     * vraie table est "homeworks", voir Homework::$table). La migration
     * n'ayant alors jamais été enregistrée comme exécutée, chaque nouveau
     * déploiement la rejouait et butait sur la colonne déjà présente.
     */
    public function up(): void
    {
        if (! Schema::hasColumn('grades', 'homework_id')) {
            Schema::table('grades', function (Blueprint $table) {
                $table->unsignedBigInteger('homework_id')->nullable()->after('subject_id');
            });
        }

        $contrainteExiste = collect(Schema::getForeignKeys('grades'))
            ->contains(fn ($fk) => in_array('homework_id', $fk['columns']));

        if (! $contrainteExiste) {
            Schema::table('grades', function (Blueprint $table) {
                $table->foreign('homework_id')->references('id')->on('homeworks')->nullOnDelete();
            });
        }
    }

    public function down(): void
    {
        Schema::table('grades', function (Blueprint $table) {
            $table->dropForeign(['homework_id']);
            $table->dropColumn('homework_id');
        });
    }
};
