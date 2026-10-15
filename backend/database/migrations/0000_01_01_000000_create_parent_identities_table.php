<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Relie les comptes d'un même parent lorsqu'il a des enfants dans
     * plusieurs écoles (donc plusieurs comptes `users`, un par tenant).
     */
    public function up(): void
    {
        Schema::create('parent_identities', function (Blueprint $table) {
            $table->id();
            $table->string('full_name');
            $table->string('canonical_email')->nullable();
            $table->string('canonical_phone')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('parent_identities');
    }
};
