<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Permet de rattacher une note au devoir qu'elle évalue (facultatif :
     * une note peut toujours être saisie librement, sans devoir associé).
     */
    public function up(): void
    {
        Schema::table('grades', function (Blueprint $table) {
            $table->foreignId('homework_id')->nullable()->after('subject_id')->constrained()->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('grades', function (Blueprint $table) {
            $table->dropConstrainedForeignId('homework_id');
        });
    }
};
