<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Masquage personnel (par utilisateur) d'une annonce, d'une observation
     * de comportement ou d'une conversation — sans l'affecter pour les
     * autres utilisateurs (archive polymorphique, docs/PRODUCT_ARCHITECTURE.md).
     */
    public function up(): void
    {
        Schema::create('item_archives', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('archivable_type');
            $table->unsignedBigInteger('archivable_id');
            $table->timestamps();

            $table->unique(['user_id', 'archivable_type', 'archivable_id'], 'item_archives_unique');
            $table->index(['archivable_type', 'archivable_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('item_archives');
    }
};
