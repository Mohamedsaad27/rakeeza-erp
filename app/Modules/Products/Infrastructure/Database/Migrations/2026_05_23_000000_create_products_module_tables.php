<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. brands
        Schema::create('brands', function (Blueprint $table) {
            $table->uuid('brand_id')->primary();
            $table->uuid('tenant_id')->index('brands_tenant_id_idx');
            $table->string('name_en');
            $table->string('name_ar');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // 2. categories
        Schema::create('categories', function (Blueprint $table) {
            $table->uuid('category_id')->primary();
            $table->uuid('tenant_id')->index('categories_tenant_id_idx');
            $table->uuid('parent_id')->nullable()->index('categories_parent_id_fk')->comment('NULL = top-level category');
            $table->string('name_en');
            $table->string('name_ar');
            $table->smallInteger('sort_order')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('parent_id')->references('category_id')->on('categories')->onDelete('set null');
        });

        // 3. units
        Schema::create('units', function (Blueprint $table) {
            $table->uuid('unit_id')->primary();
            $table->uuid('tenant_id')->index('units_tenant_id_idx');
            $table->string('actual_name_en');
            $table->string('actual_name_ar');
            $table->string('short_name_en', 50)->nullable();
            $table->string('short_name_ar', 50)->nullable();
            $table->uuid('base_unit_id')->nullable()->index('units_base_unit_id_fk')->comment('NULL = this IS the base unit');
            $table->decimal('base_unit_multiplier', 10, 4)->nullable()->comment('e.g. 12 if 1 box = 12 pieces');
            $table->boolean('base_unit_is_largest')->default(false);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('base_unit_id')->references('unit_id')->on('units')->onDelete('set null');
        });

        // 4. products
        Schema::create('products', function (Blueprint $table) {
            $table->uuid('product_id')->primary();
            $table->uuid('tenant_id')->index('products_tenant_id_idx');
            $table->string('name_en');
            $table->string('name_ar');
            $table->string('sku', 100)->nullable();
            $table->string('barcode', 100)->nullable();
            $table->text('description_en')->nullable();
            $table->text('description_ar')->nullable();
            $table->tinyInteger('type')->default(1)->comment('1=standard | 2=variable | 3=service | 4=combo');
            $table->uuid('unit_id')->nullable()->index('products_unit_id_fk')->comment('Base/default unit');
            $table->uuid('brand_id')->nullable()->index('products_brand_id_fk');
            $table->uuid('category_id')->nullable()->index('products_category_id_fk')->comment('Sub-category');
            $table->uuid('main_category_id')->nullable()->index('products_main_category_id_fk')->comment('Main/parent category');
            $table->decimal('unit_price', 15, 4)->default(0.0000)->comment('Default sale price in base unit');
            $table->decimal('purchase_price', 15, 4)->default(0.0000);
            $table->decimal('tax_rate', 5, 2)->default(0.00);
            $table->boolean('enable_stock')->default(true);
            $table->decimal('quantity_alert', 15, 4)->default(0.0000);
            $table->decimal('min_sale', 15, 4)->nullable();
            $table->decimal('max_sale', 15, 4)->nullable();
            $table->boolean('for_sale')->default(true);
            $table->boolean('is_serialized')->default(false);
            $table->boolean('has_expiry')->default(false);
            $table->text('notes')->nullable();
            $table->uuid('created_by')->nullable()->index('products_created_by_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'sku'], 'products_tenant_sku_idx');
            $table->unique(['tenant_id', 'barcode'], 'products_tenant_barcode_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('unit_id')->references('unit_id')->on('units')->onDelete('set null');
            $table->foreign('brand_id')->references('brand_id')->on('brands')->onDelete('set null');
            $table->foreign('category_id')->references('category_id')->on('categories')->onDelete('set null');
            $table->foreign('main_category_id')->references('category_id')->on('categories')->onDelete('set null');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('set null');
        });

        // 5. product_variants
        Schema::create('product_variants', function (Blueprint $table) {
            $table->uuid('product_variant_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('product_id')->index('pv_product_id_fk');
            $table->string('name_en')->comment('e.g. Red / Large');
            $table->string('name_ar');
            $table->string('sku', 100)->nullable();
            $table->string('barcode', 100)->nullable();
            $table->decimal('unit_price', 15, 4)->default(0.0000);
            $table->decimal('purchase_price', 15, 4)->default(0.0000);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'product_id'], 'pv_tenant_product_idx');
            $table->index(['tenant_id', 'sku'], 'pv_tenant_sku_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
        });

        // 6. product_unit_details
        Schema::create('product_unit_details', function (Blueprint $table) {
            $table->uuid('product_unit_detail_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('product_id')->index('pud_product_id_fk');
            $table->uuid('unit_id')->index('pud_unit_id_fk');
            $table->decimal('sale_price', 15, 4)->default(0.0000);
            $table->decimal('purchase_price', 15, 4)->default(0.0000);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'product_id', 'unit_id'], 'pud_product_unit_unique');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
            $table->foreign('unit_id')->references('unit_id')->on('units')->onDelete('cascade');
        });

        // 7. product_price_histories
        Schema::create('product_price_histories', function (Blueprint $table) {
            $table->uuid('product_price_history_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('product_id')->index('pph_product_id_fk');
            $table->uuid('unit_id');
            $table->decimal('old_unit_price', 15, 4);
            $table->decimal('new_unit_price', 15, 4);
            $table->uuid('changed_by')->index('pph_changed_by_fk');
            $table->timestamp('created_at')->nullable();

            $table->index(['tenant_id', 'product_id'], 'pph_tenant_product_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
            $table->foreign('changed_by')->references('user_id')->on('users')->onDelete('cascade');
        });

        // 8. sales_segment_products
        Schema::create('sales_segment_products', function (Blueprint $table) {
            $table->uuid('sales_segment_product_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('sales_segment_id')->index('ssp_sales_segment_id_fk');
            $table->uuid('product_id')->index('ssp_product_id_fk');
            $table->uuid('unit_id')->index('ssp_unit_id_fk');
            $table->decimal('price', 15, 4);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'sales_segment_id', 'product_id', 'unit_id'], 'ssp_segment_product_unit_unique');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('sales_segment_id')->references('sales_segment_id')->on('sales_segments')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
            $table->foreign('unit_id')->references('unit_id')->on('units')->onDelete('cascade');
        });

        // 9. serial_numbers
        Schema::create('serial_numbers', function (Blueprint $table) {
            $table->uuid('serial_number_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('product_id');
            $table->uuid('warehouse_id')->nullable()->index('sn_warehouse_id_fk')->comment('Deferred FK');
            $table->string('serial_no', 100);
            $table->tinyInteger('status')->default(1)->comment('1=available | 2=sold | 3=returned | 4=defective');
            $table->uuid('sold_in_transaction_id')->nullable()->comment('Deferred FK');
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'serial_no'], 'serial_numbers_tenant_serial_unique');
            $table->index(['tenant_id', 'product_id'], 'sn_tenant_product_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
        });

        // 10. batch_numbers
        Schema::create('batch_numbers', function (Blueprint $table) {
            $table->uuid('batch_number_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('product_id');
            $table->uuid('warehouse_id')->nullable()->index('bn_warehouse_id_fk')->comment('Deferred FK');
            $table->string('batch_no', 100);
            $table->date('expiry_date')->nullable();
            $table->date('manufacture_date')->nullable();
            $table->decimal('qty_received', 15, 4)->default(0.0000);
            $table->decimal('qty_remaining', 15, 4)->default(0.0000);
            $table->decimal('unit_cost', 15, 4)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'product_id', 'batch_no'], 'batch_numbers_tenant_product_batch_unique');
            $table->index(['tenant_id', 'product_id'], 'bn_tenant_product_idx');
            $table->index(['tenant_id', 'expiry_date'], 'bn_expiry_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('batch_numbers');
        Schema::dropIfExists('serial_numbers');
        Schema::dropIfExists('sales_segment_products');
        Schema::dropIfExists('product_price_histories');
        Schema::dropIfExists('product_unit_details');
        Schema::dropIfExists('product_variants');
        Schema::dropIfExists('products');
        Schema::dropIfExists('units');
        Schema::dropIfExists('categories');
        Schema::dropIfExists('brands');
        Schema::enableForeignKeyConstraints();
    }
};
