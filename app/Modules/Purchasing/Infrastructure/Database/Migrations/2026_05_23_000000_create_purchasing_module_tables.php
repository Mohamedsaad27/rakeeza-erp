<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. purchase_transactions
        Schema::create('purchase_transactions', function (Blueprint $table) {
            $table->uuid('purchase_transaction_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('branch_id')->nullable()->index('ptx_branch_id_fk');
            $table->uuid('warehouse_id')->nullable()->index('ptx_warehouse_id_fk');
            $table->uuid('contact_id')->nullable()->index('ptx_tenant_contact_idx')->comment('Supplier');
            $table->uuid('tax_id')->nullable()->index('ptx_tax_id_fk');
            $table->uuid('purchase_order_id')->nullable()->index('ptx_purchase_order_id_fk');
            $table->uuid('created_by')->nullable()->index('ptx_created_by_fk');
            $table->uuid('return_of_id')->nullable()->index('ptx_return_of_id_fk');
            $table->tinyInteger('type')->default(1)->comment('1=purchase | 2=purchase_return');
            $table->tinyInteger('status')->default(1)->comment('1=draft | 2=confirmed | 3=cancelled');
            $table->string('ref_no', 100)->nullable();
            $table->string('supplier_ref_no', 100)->nullable();
            $table->timestamp('transaction_date')->useCurrent();
            $table->decimal('subtotal', 15, 4)->default(0.0000);
            $table->tinyInteger('discount_type')->nullable()->comment('1=percentage | 2=fixed_price');
            $table->decimal('discount_value', 15, 4)->default(0.0000);
            $table->decimal('tax_amount', 15, 4)->default(0.0000);
            $table->decimal('shipping_cost', 15, 4)->default(0.0000);
            $table->decimal('final_price', 15, 4)->default(0.0000);
            $table->tinyInteger('payment_type')->default(1)->comment('1=cash | 2=credit');
            $table->tinyInteger('payment_status')->default(1)->comment('1=due | 2=partial | 3=paid');
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'type'], 'ptx_tenant_type_idx');
            $table->index(['tenant_id', 'transaction_date'], 'ptx_tenant_date_idx');
            $table->index(['tenant_id', 'status'], 'ptx_tenant_status_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('set null');
            $table->foreign('warehouse_id')->references('warehouse_id')->on('warehouses')->onDelete('set null');
            $table->foreign('contact_id')->references('contact_id')->on('contacts')->onDelete('set null');
            $table->foreign('tax_id')->references('tax_id')->on('taxes')->onDelete('set null');
            $table->foreign('purchase_order_id')->references('purchase_order_id')->on('purchase_orders')->onDelete('set null');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('set null');
            $table->foreign('return_of_id')->references('purchase_transaction_id')->on('purchase_transactions')->onDelete('set null');
        });

        // 2. purchase_transaction_lines
        Schema::create('purchase_transaction_lines', function (Blueprint $table) {
            $table->uuid('purchase_transaction_line_id')->primary();
            $table->uuid('tenant_id')->index('ptxl_tenant_id_idx');
            $table->uuid('purchase_transaction_id')->index('ptxl_purchase_transaction_id_fk');
            $table->uuid('product_id')->index('ptxl_product_id_fk');
            $table->uuid('unit_id')->index('ptxl_unit_id_fk');
            $table->uuid('batch_id')->nullable()->index('ptxl_batch_id_fk');
            $table->decimal('quantity', 15, 4)->default(0.0000);
            $table->decimal('main_unit_quantity', 15, 4)->default(0.0000);
            $table->decimal('return_quantity', 15, 4)->default(0.0000);
            $table->decimal('unit_price', 15, 4)->default(0.0000);
            $table->decimal('discount', 15, 4)->default(0.0000);
            $table->decimal('tax_rate', 5, 2)->default(0.00);
            $table->decimal('total', 15, 4)->default(0.0000);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('purchase_transaction_id')->references('purchase_transaction_id')->on('purchase_transactions')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
            $table->foreign('unit_id')->references('unit_id')->on('units')->onDelete('cascade');
            $table->foreign('batch_id')->references('batch_number_id')->on('batch_numbers')->onDelete('set null');
        });

        // 3. purchase_orders
        Schema::create('purchase_orders', function (Blueprint $table) {
            $table->uuid('purchase_order_id')->primary();
            $table->uuid('tenant_id')->index('po_tenant_id_idx');
            $table->uuid('branch_id')->index('po_branch_id_fk');
            $table->uuid('warehouse_id')->nullable()->index('po_warehouse_id_fk');
            $table->uuid('contact_id')->index('po_contact_id_fk')->comment('Supplier');
            $table->string('ref_no', 100)->nullable();
            $table->date('po_date');
            $table->date('expected_date')->nullable();
            $table->tinyInteger('status')->default(1)->comment('1=draft | 2=sent | 3=partial | 4=received | 5=cancelled');
            $table->decimal('total', 15, 4)->default(0.0000);
            $table->decimal('tax_amount', 15, 4)->default(0.0000);
            $table->decimal('shipping_cost', 15, 4)->default(0.0000);
            $table->decimal('final_price', 15, 4)->default(0.0000);
            $table->text('notes')->nullable();
            $table->uuid('created_by')->index('po_created_by_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('restrict');
            $table->foreign('warehouse_id')->references('warehouse_id')->on('warehouses')->onDelete('set null');
            $table->foreign('contact_id')->references('contact_id')->on('contacts')->onDelete('restrict');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('restrict');
        });

        // 4. purchase_order_lines
        Schema::create('purchase_order_lines', function (Blueprint $table) {
            $table->uuid('purchase_order_line_id')->primary();
            $table->uuid('purchase_order_id')->index('pol_purchase_order_id_fk');
            $table->uuid('product_id')->index('pol_product_id_fk');
            $table->uuid('unit_id')->index('pol_unit_id_fk');
            $table->decimal('quantity_ordered', 15, 4);
            $table->decimal('quantity_received', 15, 4)->default(0.0000);
            $table->decimal('unit_price', 15, 4);
            $table->decimal('discount', 15, 4)->default(0.0000);
            $table->decimal('tax_rate', 5, 2)->default(0.00);
            $table->decimal('total', 15, 4);
            $table->softDeletes();

            $table->foreign('purchase_order_id')->references('purchase_order_id')->on('purchase_orders')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
            $table->foreign('unit_id')->references('unit_id')->on('units')->onDelete('cascade');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('purchase_order_lines');
        Schema::dropIfExists('purchase_orders');
        Schema::dropIfExists('purchase_transaction_lines');
        Schema::dropIfExists('purchase_transactions');
        Schema::enableForeignKeyConstraints();
    }
};
