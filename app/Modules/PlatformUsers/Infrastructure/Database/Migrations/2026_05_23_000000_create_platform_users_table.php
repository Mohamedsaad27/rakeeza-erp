<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('platform_users', function (Blueprint $table) {
            $table->uuid('platform_user_id')->primary();
            $table->string('name');
            $table->string('email')->unique('platform_users_email_unique');
            $table->string('password');
            $table->boolean('is_active')->default(true)->index('platform_users_is_active_idx');
            $table->string('profile_image', 500)->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->timestamp('last_login_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('platform_users');
    }
};
