<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        Schema::create('media_files', function (Blueprint $table) {
            $table->uuid('media_file_id')->primary();
            $table->uuid('tenant_id');
            $table->string('model_type');
            $table->uuid('model_id');
            $table->string('collection', 100)->default('default');
            $table->string('file_name');
            $table->string('original_name');
            $table->string('mime_type', 100)->nullable();
            $table->string('disk', 50)->default('public');
            $table->string('file_path', 500);
            $table->unsignedBigInteger('file_size');
            $table->unsignedInteger('order')->default(0);
            $table->uuid('created_by')->nullable()->index('media_files_created_by_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'model_type', 'model_id'], 'media_files_tenant_model_idx');
            $table->index(['tenant_id', 'collection'], 'media_files_collection_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('set null');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('media_files');
        Schema::enableForeignKeyConstraints();
    }
};
