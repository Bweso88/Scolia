<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Catalogue commercial piloté depuis le back-office plateforme.
     * Aucun prix ni quota n'est codé en dur dans l'application
     * (voir docs/PRODUCT_ARCHITECTURE.md §18).
     */
    public function up(): void
    {
        Schema::create('plans', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('name');
            $table->unsignedInteger('max_students');
            $table->unsignedInteger('price_amount');
            $table->string('price_currency', 3)->default('XOF');
            $table->enum('billing_period', ['monthly', 'yearly'])->default('yearly');
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('plans');
    }
};
