<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. governorates
        Schema::create('governorates', function (Blueprint $table) {
            $table->uuid('governorate_id')->primary();
            $table->string('governorate_name_ar');
            $table->string('governorate_name_en');
            $table->timestamps();
        });

        // 2. cities
        Schema::create('cities', function (Blueprint $table) {
            $table->uuid('city_id')->primary();
            $table->uuid('governorate_id')->index('cities_governorate_id_fk');
            $table->string('city_name_ar');
            $table->string('city_name_en');
            $table->timestamps();

            $table->foreign('governorate_id')->references('governorate_id')->on('governorates')->onDelete('cascade');
        });

        // 3. activity_types
        Schema::create('activity_types', function (Blueprint $table) {
            $table->uuid('activity_type_id')->primary();
            $table->uuid('tenant_id')->index('activity_types_tenant_id_idx');
            $table->string('name_en');
            $table->string('name_ar');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // 4. sales_segments
        Schema::create('sales_segments', function (Blueprint $table) {
            $table->uuid('sales_segment_id')->primary();
            $table->uuid('tenant_id')->index('sales_segments_tenant_id_idx');
            $table->string('name_en');
            $table->string('name_ar');
            $table->string('description_en', 500)->nullable();
            $table->string('description_ar', 500)->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // 5. contact_groups
        Schema::create('contact_groups', function (Blueprint $table) {
            $table->uuid('contact_group_id')->primary();
            $table->uuid('tenant_id')->index('contact_groups_tenant_id_idx');
            $table->string('name_en');
            $table->string('name_ar');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // 6. contacts
        Schema::create('contacts', function (Blueprint $table) {
            $table->uuid('contact_id')->primary();
            $table->uuid('tenant_id');
            $table->tinyInteger('type')->default(1)->comment('1=customer | 2=supplier | 3=both');
            $table->string('name_en');
            $table->string('name_ar');
            $table->string('code', 50)->nullable();
            $table->string('contact_code', 50)->nullable();
            $table->string('tax_number', 100)->nullable();
            $table->string('national_id', 50)->nullable();
            $table->string('contact_person')->nullable();
            $table->string('phone', 50)->nullable();
            $table->string('email', 255)->nullable();
            $table->text('address')->nullable();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            
            $table->uuid('governorate_id')->nullable()->index('contacts_governorate_id_fk');
            $table->uuid('city_id')->nullable()->index('contacts_city_id_fk');
            $table->uuid('activity_type_id')->nullable()->index('contacts_activity_type_id_fk');
            $table->uuid('sales_segment_id')->nullable()->index('contacts_sales_segment_id_fk');
            $table->uuid('contact_group_id')->nullable()->index('contacts_contact_group_id_fk');
            $table->uuid('assigned_to')->nullable()->index('contacts_assigned_to_fk')->comment('Sales rep user_id');
            
            $table->decimal('balance', 15, 4)->default(0.0000)->comment('Denormalized cache');
            $table->decimal('opening_balance', 15, 4)->default(0.0000);
            $table->decimal('credit_limit', 15, 4)->default(0.0000);
            $table->boolean('is_active')->default(true);
            $table->boolean('is_default')->default(false);
            $table->json('tags')->nullable();
            $table->text('notes')->nullable();
            
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'contact_code'], 'contacts_contact_code_tenant_unique');
            $table->unique(['tenant_id', 'email'], 'contacts_email_tenant_unique');
            $table->index(['tenant_id', 'type'], 'contacts_tenant_type_idx');
            $table->index(['tenant_id', 'sales_segment_id'], 'contacts_tenant_segment_idx');

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('governorate_id')->references('governorate_id')->on('governorates')->onDelete('set null');
            $table->foreign('city_id')->references('city_id')->on('cities')->onDelete('set null');
            $table->foreign('activity_type_id')->references('activity_type_id')->on('activity_types')->onDelete('set null');
            $table->foreign('sales_segment_id')->references('sales_segment_id')->on('sales_segments')->onDelete('set null');
            $table->foreign('contact_group_id')->references('contact_group_id')->on('contact_groups')->onDelete('set null');
            $table->foreign('assigned_to')->references('user_id')->on('users')->onDelete('set null');
        });

        // 7. contact_notes
        Schema::create('contact_notes', function (Blueprint $table) {
            $table->uuid('contact_note_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('contact_id');
            $table->text('note');
            $table->uuid('created_by')->index('contact_notes_created_by_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'contact_id'], 'contact_notes_tenant_contact_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('contact_id')->references('contact_id')->on('contacts')->onDelete('cascade');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('cascade');
        });

        // 8. contact_addresses
        Schema::create('contact_addresses', function (Blueprint $table) {
            $table->uuid('contact_address_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('contact_id');
            $table->string('label', 100)->nullable()->comment('e.g. warehouse | headquarters | branch');
            $table->text('address');
            $table->uuid('governorate_id')->nullable()->index('ca_governorate_id_foreign');
            $table->uuid('city_id')->nullable()->index('ca_city_id_foreign');
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->boolean('is_default')->default(false);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'contact_id'], 'contact_addresses_tenant_contact_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('contact_id')->references('contact_id')->on('contacts')->onDelete('cascade');
            $table->foreign('governorate_id')->references('governorate_id')->on('governorates')->onDelete('set null');
            $table->foreign('city_id')->references('city_id')->on('cities')->onDelete('set null');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('contact_addresses');
        Schema::dropIfExists('contact_notes');
        Schema::dropIfExists('contacts');
        Schema::dropIfExists('contact_groups');
        Schema::dropIfExists('sales_segments');
        Schema::dropIfExists('activity_types');
        Schema::dropIfExists('cities');
        Schema::dropIfExists('governorates');
        Schema::enableForeignKeyConstraints();
    }
};
