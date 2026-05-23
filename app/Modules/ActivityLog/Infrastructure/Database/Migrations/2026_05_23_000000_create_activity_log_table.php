<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        Schema::create('activity_log', function (Blueprint $table) {
            $table->uuid('activity_lo_id')->primary();
            $table->uuid('tenant_id')->index('al_tenant_id_idx');
            $table->uuid('user_id')->index('al_user_id_fk');
            $table->uuid('subject_id')->nullable();
            $table->string('subject_type')->nullable();
            $table->string('event', 100)->nullable()->comment('created | updated | deleted');
            $table->string('module', 100)->nullable()->comment('sales | inventory | hr | finance | crm');
            $table->string('description', 500)->nullable();
            $table->string('title', 255);
            $table->json('properties')->nullable()->comment('Before/after diff');
            $table->string('ip_address', 45)->nullable();
            $table->timestamp('created_at')->nullable();

            $table->index(['tenant_id', 'module'], 'al_tenant_module_idx');
            $table->index(['tenant_id', 'subject_type', 'subject_id'], 'al_tenant_subject_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('user_id')->references('user_id')->on('users')->onDelete('cascade');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('activity_log');
        Schema::enableForeignKeyConstraints();
    }
};
