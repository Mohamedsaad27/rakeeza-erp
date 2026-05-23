<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. warehouses
        Schema::create('warehouses', function (Blueprint $table) {
            $table->uuid('warehouse_id')->primary();
            $table->uuid('tenant_id')->index('warehouses_tenant_id_idx');
            $table->uuid('branch_id')->nullable()->index('warehouses_branch_id_fk');
            $table->string('name_en');
            $table->string('name_ar');
            $table->string('code', 50)->nullable();
            $table->text('address')->nullable();
            $table->boolean('is_active')->default(true);
            $table->boolean('is_default')->default(false);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('set null');
        });

        // 2. stock_levels
        Schema::create('stock_levels', function (Blueprint $table) {
            $table->uuid('stock_level_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('warehouse_id')->index('stock_levels_warehouse_id_fk');
            $table->uuid('product_id')->index('stock_levels_product_id_fk');
            $table->uuid('unit_id')->index('stock_levels_unit_id_fk');
            $table->decimal('qty_available', 15, 4)->default(0.0000);
            $table->decimal('qty_reserved', 15, 4)->default(0.0000)->comment('Reserved by pending orders');
            $table->decimal('qty_on_order', 15, 4)->default(0.0000)->comment('In open purchase orders');
            $table->timestamp('updated_at')->nullable();

            $table->unique(['tenant_id', 'warehouse_id', 'product_id', 'unit_id'], 'stock_levels_unique');
            $table->index(['tenant_id', 'product_id'], 'stock_levels_tenant_product_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('warehouse_id')->references('warehouse_id')->on('warehouses')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
            $table->foreign('unit_id')->references('unit_id')->on('units')->onDelete('cascade');
        });

        // 3. stock_movements
        Schema::create('stock_movements', function (Blueprint $table) {
            $table->uuid('stock_movement_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('warehouse_id')->index('sm_warehouse_id_fk');
            $table->uuid('product_id');
            $table->uuid('unit_id');
            $table->string('reference_type', 50)->nullable()->comment('sales_transaction | purchase_transaction | etc');
            $table->uuid('reference_id')->nullable();
            $table->string('movement_type', 30)->comment('purchase | sale | transfer_in | adjustment | etc');
            $table->decimal('quantity', 15, 4)->comment('Positive=in | Negative=out');
            $table->decimal('unit_cost', 15, 4)->nullable();
            $table->string('reference_no', 100)->nullable();
            $table->uuid('batch_id')->nullable()->index('sm_batch_id_fk');
            $table->uuid('serial_id')->nullable()->index('sm_serial_id_fk');
            $table->text('note')->nullable();
            $table->uuid('created_by')->nullable()->index('sm_created_by_fk');
            $table->timestamp('created_at')->nullable();

            $table->index(['tenant_id', 'product_id'], 'sm_tenant_product_idx');
            $table->index(['tenant_id', 'created_at'], 'sm_tenant_date_idx');
            $table->index(['reference_type', 'reference_id'], 'sm_reference_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('warehouse_id')->references('warehouse_id')->on('warehouses')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
            $table->foreign('unit_id')->references('unit_id')->on('units')->onDelete('cascade');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('set null');
            $table->foreign('batch_id')->references('batch_number_id')->on('batch_numbers')->onDelete('set null');
            $table->foreign('serial_id')->references('serial_number_id')->on('serial_numbers')->onDelete('set null');
        });

        // 4. stock_adjustments
        Schema::create('stock_adjustments', function (Blueprint $table) {
            $table->uuid('stock_adjustment_id')->primary();
            $table->uuid('tenant_id')->index('sa_tenant_id_idx');
            $table->uuid('warehouse_id')->index('sa_warehouse_id_fk');
            $table->string('ref_no', 100)->nullable();
            $table->string('reason', 500)->nullable();
            $table->tinyInteger('status')->default(1)->comment('1=draft | 2=approved | 3=rejected');
            $table->uuid('approved_by')->nullable()->index('sa_approved_by_fk');
            $table->timestamp('approved_at')->nullable();
            $table->uuid('created_by')->index('sa_created_by_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('warehouse_id')->references('warehouse_id')->on('warehouses')->onDelete('restrict');
            $table->foreign('approved_by')->references('user_id')->on('users')->onDelete('set null');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('cascade');
        });

        // 5. stock_adjustment_lines
        Schema::create('stock_adjustment_lines', function (Blueprint $table) {
            $table->uuid('stock_adjustment_line_id')->primary();
            $table->uuid('stock_adjustment_id')->index('sal_stock_adjustment_id_fk');
            $table->uuid('product_id')->index('sal_product_id_fk');
            $table->uuid('unit_id');
            $table->decimal('qty_system', 15, 4)->comment('What the system recorded');
            $table->decimal('qty_actual', 15, 4)->comment('What was physically counted');
            $table->softDeletes();

            $table->foreign('stock_adjustment_id')->references('stock_adjustment_id')->on('stock_adjustments')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
            $table->foreign('unit_id')->references('unit_id')->on('units')->onDelete('cascade');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('stock_adjustment_lines');
        Schema::dropIfExists('stock_adjustments');
        Schema::dropIfExists('stock_movements');
        Schema::dropIfExists('stock_levels');
        Schema::dropIfExists('warehouses');
        Schema::enableForeignKeyConstraints();
    }
};
