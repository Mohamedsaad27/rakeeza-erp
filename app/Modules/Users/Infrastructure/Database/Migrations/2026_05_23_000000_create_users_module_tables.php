<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // user_preferences — per-tenant user settings
        Schema::create('user_preferences', function (Blueprint $table) {
            $table->uuid('preference_id')->primary();
            $table->uuid('tenant_id')->index('up_tenant_id_idx');
            $table->uuid('user_id');
            $table->string('key', 100);
            $table->text('value')->nullable();
            $table->timestamps();

            $table->unique(['tenant_id', 'user_id', 'key'], 'up_tenant_user_key_unique');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('user_id')->references('user_id')->on('users')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_preferences');
    }
};
