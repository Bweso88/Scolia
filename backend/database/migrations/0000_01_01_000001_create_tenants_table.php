<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Une ligne = une école cliente. Voir docs/PRODUCT_ARCHITECTURE.md §6 :
     * base unique, isolation par tenant_id sur toutes les tables métier.
     */
    public function up(): void
    {
        Schema::create('tenants', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->enum('status', ['trial', 'active', 'suspended', 'cancelled'])->default('trial');
            $table->unsignedTinyInteger('school_year_start_month')->default(9);
            $table->string('timezone')->default('Africa/Abidjan');
            $table->string('locale', 5)->default('fr');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tenants');
    }
};
