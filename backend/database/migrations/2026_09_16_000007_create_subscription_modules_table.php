<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /** Activation/désactivation d'un module indépendamment du plan. */
    public function up(): void
    {
        Schema::create('subscription_modules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('module_key');
            $table->boolean('is_enabled')->default(true);
            $table->timestamps();

            $table->unique(['tenant_id', 'module_key']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_modules');
    }
};
