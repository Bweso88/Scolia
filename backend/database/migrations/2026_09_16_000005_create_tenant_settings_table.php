<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Personnalisation / marque blanche par école
     * (voir docs/PRODUCT_ARCHITECTURE.md §16).
     */
    public function up(): void
    {
        Schema::create('tenant_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('display_name');
            $table->string('logo_path')->nullable();
            $table->string('cover_image_path')->nullable();
            $table->string('primary_color', 7)->default('#2F5D50');
            $table->string('secondary_color', 7)->default('#1F4038');
            $table->string('phone')->nullable();
            $table->string('email')->nullable();
            $table->string('address')->nullable();
            $table->string('website')->nullable();
            $table->foreignId('current_school_year_id')->nullable()->constrained('school_years')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tenant_settings');
    }
};
