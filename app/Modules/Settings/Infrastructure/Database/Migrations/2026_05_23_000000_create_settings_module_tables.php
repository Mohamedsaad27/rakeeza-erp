<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. tenant_settings
        Schema::create('tenant_settings', function (Blueprint $table) {
            $table->uuid('tenant_setting_id')->primary();
            $table->uuid('tenant_id')->unique('tenant_settings_tenant_id_unique');
            
            // branding
            $table->string('logo', 500)->nullable();
            $table->string('site_image', 500)->nullable();
            $table->string('image_invoice', 500)->nullable();
            $table->string('site_name', 255)->nullable();
            
            // locale
            $table->string('currency', 10)->default('EGP');
            $table->string('currency_symbol', 10)->default('ج.م');
            $table->string('date_format', 50)->default('Y-m-d');
            $table->string('time_zone', 100)->default('Africa/Cairo');
            $table->string('language', 10)->default('ar');
            
            // tax & finance
            $table->string('tax_number', 100)->nullable();
            $table->decimal('default_tax_rate', 5, 2)->default(0.00);
            $table->date('fiscal_year_start')->nullable();
            $table->decimal('default_credit_limit', 15, 4)->default(0.0000);
            
            // behaviour flags
            $table->boolean('allow_unit_price_update')->default(false);
            $table->boolean('prevent_buy_below_purchase_price')->default(true);
            $table->boolean('allow_negative_stock')->default(false);
            
            // printing
            $table->boolean('thermal_printing')->default(false);
            $table->boolean('classic_printing')->default(true);
            
            // invoice & catalog display flags
            $table->json('invoice_display')->nullable();
            $table->json('catalog_display')->nullable();
            
            // contact / social
            $table->string('email', 255)->nullable();
            $table->string('phone', 255)->nullable();
            $table->text('address')->nullable();
            $table->text('about_us')->nullable();
            $table->string('facebook', 255)->nullable();
            $table->string('instagram', 255)->nullable();
            $table->string('twitter', 255)->nullable();
            $table->string('linkedin', 255)->nullable();
            $table->text('invoice_footer_note')->nullable();
            
            $table->timestamps();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // 2. settings
        Schema::create('settings', function (Blueprint $table) {
            $table->uuid('setting_id')->primary();
            $table->uuid('tenant_id')->index('settings_tenant_id_idx');
            $table->string('key', 150)->comment('format: module.setting_name — e.g. sales.invoice_prefix');
            $table->text('value')->nullable();
            $table->timestamps();

            $table->unique(['tenant_id', 'key'], 'settings_tenant_key_unique');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('settings');
        Schema::dropIfExists('tenant_settings');
        Schema::enableForeignKeyConstraints();
    }
};
