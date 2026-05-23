<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. sales_transactions
        Schema::create('sales_transactions', function (Blueprint $table) {
            $table->uuid('sales_transaction_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('branch_id')->nullable()->index('stx_branch_id_fk');
            $table->uuid('warehouse_id')->nullable()->index('stx_warehouse_id_fk');
            $table->uuid('contact_id')->nullable()->index('stx_contact_id_fk')->comment('Customer');
            $table->uuid('tax_id')->nullable()->index('stx_tax_id_fk');
            $table->uuid('created_by')->nullable()->index('stx_created_by_fk');
            $table->uuid('return_of_id')->nullable()->index('stx_return_of_id_fk');
            $table->tinyInteger('type')->default(1)->comment('1=sell | 2=sell_return');
            $table->tinyInteger('status')->default(1)->comment('1=draft | 2=confirmed | 3=cancelled');
            $table->string('ref_no', 100)->nullable();
            $table->timestamp('transaction_date')->useCurrent();
            $table->decimal('subtotal', 15, 4)->default(0.0000);
            $table->tinyInteger('discount_type')->nullable()->comment('1=percentage | 2=fixed_price');
            $table->decimal('discount_value', 15, 4)->default(0.0000);
            $table->decimal('tax_amount', 15, 4)->default(0.0000);
            $table->decimal('shipping_cost', 15, 4)->default(0.0000);
            $table->decimal('final_price', 15, 4)->default(0.0000);
            $table->tinyInteger('payment_type')->default(1)->comment('1=cash | 2=credit');
            $table->tinyInteger('payment_status')->default(1)->comment('1=due | 2=partial | 3=paid');
            $table->tinyInteger('delivery_status')->default(1)->comment('1=ordered | 2=shipped | 3=delivered');
            $table->string('delivery_status_note', 255)->nullable();
            $table->string('transaction_from', 50)->nullable()->comment('pos | online | api');
            $table->uuid('pos_session_id')->nullable()->index('stx_pos_session_id_fk');
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'type'], 'stx_tenant_type_idx');
            $table->index(['tenant_id', 'transaction_date'], 'stx_tenant_date_idx');
            $table->index(['tenant_id', 'status'], 'stx_tenant_status_idx');
            $table->index(['tenant_id', 'contact_id'], 'stx_tenant_contact_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('set null');
            $table->foreign('warehouse_id')->references('warehouse_id')->on('warehouses')->onDelete('set null');
            $table->foreign('contact_id')->references('contact_id')->on('contacts')->onDelete('set null');
            $table->foreign('return_of_id')->references('sales_transaction_id')->on('sales_transactions')->onDelete('set null');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('set null');
            $table->foreign('tax_id')->references('tax_id')->on('taxes')->onDelete('set null');
        });

        // 2. pos_sessions
        Schema::create('pos_sessions', function (Blueprint $table) {
            $table->uuid('pos_session_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('branch_id')->index('pos_branch_id_fk');
            $table->uuid('warehouse_id')->nullable()->index('pos_warehouse_id_fk');
            $table->uuid('user_id')->index('pos_user_id_fk')->comment('Cashier');
            $table->uuid('account_id')->nullable()->index('pos_account_id_fk')->comment('Cash drawer account');
            $table->tinyInteger('status')->default(1)->comment('1=open | 2=closed');
            $table->decimal('opening_cash', 15, 4)->default(0.0000);
            $table->decimal('closing_cash', 15, 4)->nullable();
            $table->decimal('cash_difference', 15, 4)->nullable()->comment('closing_cash - expected_cash');
            $table->decimal('total_sales', 15, 4)->default(0.0000);
            $table->decimal('total_returns', 15, 4)->default(0.0000);
            $table->decimal('total_payments', 15, 4)->default(0.0000);
            $table->timestamp('opened_at')->nullable();
            $table->timestamp('closed_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'status'], 'pos_status_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('restrict');
            $table->foreign('warehouse_id')->references('warehouse_id')->on('warehouses')->onDelete('set null');
            $table->foreign('user_id')->references('user_id')->on('users')->onDelete('restrict');
            $table->foreign('account_id')->references('account_id')->on('accounts')->onDelete('set null');
        });

        // Add foreign key from sales_transactions to pos_sessions
        Schema::table('sales_transactions', function (Blueprint $table) {
            $table->foreign('pos_session_id')->references('pos_session_id')->on('pos_sessions')->onDelete('set null');
        });

        // 3. sales_transaction_lines
        Schema::create('sales_transaction_lines', function (Blueprint $table) {
            $table->uuid('sales_transaction_line_id')->primary();
            $table->uuid('tenant_id')->index('stxl_tenant_id_idx');
            $table->uuid('sales_transaction_id')->index('stxl_sales_transaction_id_fk');
            $table->uuid('product_id')->index('stxl_product_id_fk');
            $table->uuid('unit_id')->index('stxl_unit_id_fk');
            $table->uuid('purchase_transaction_line_id')->nullable()->index('stxl_ptl_id_fk')->comment('Deferred FK — FIFO costing link');
            $table->uuid('batch_id')->nullable()->index('stxl_batch_id_fk');
            $table->uuid('serial_id')->nullable()->index('stxl_serial_id_fk');
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
            $table->foreign('sales_transaction_id')->references('sales_transaction_id')->on('sales_transactions')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
            $table->foreign('unit_id')->references('unit_id')->on('units')->onDelete('cascade');
            $table->foreign('batch_id')->references('batch_number_id')->on('batch_numbers')->onDelete('set null');
            $table->foreign('serial_id')->references('serial_number_id')->on('serial_numbers')->onDelete('set null');
        });

        // 4. quotations
        Schema::create('quotations', function (Blueprint $table) {
            $table->uuid('quotation_id')->primary();
            $table->uuid('tenant_id')->index('q_tenant_id_idx');
            $table->uuid('branch_id')->index('q_branch_id_fk');
            $table->uuid('contact_id')->nullable()->index('q_contact_id_fk');
            $table->string('ref_no', 100)->nullable();
            $table->date('quotation_date');
            $table->date('expiry_date')->nullable();
            $table->tinyInteger('status')->default(1)->comment('1=draft | 2=sent | 3=accepted | 4=rejected | 5=converted');
            $table->decimal('total', 15, 4)->default(0.0000);
            $table->tinyInteger('discount_type')->nullable()->comment('1=percentage | 2=fixed');
            $table->decimal('discount_value', 15, 4)->default(0.0000);
            $table->decimal('tax_amount', 15, 4)->default(0.0000);
            $table->decimal('final_price', 15, 4)->default(0.0000);
            $table->text('notes')->nullable();
            $table->uuid('converted_to_transaction_id')->nullable()->index('q_converted_to_transaction_id_fk');
            $table->uuid('created_by')->index('q_created_by_foreign');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('restrict');
            $table->foreign('contact_id')->references('contact_id')->on('contacts')->onDelete('set null');
            $table->foreign('converted_to_transaction_id')->references('sales_transaction_id')->on('sales_transactions')->onDelete('set null');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('restrict');
        });

        // 5. quotation_lines
        Schema::create('quotation_lines', function (Blueprint $table) {
            $table->uuid('quotation_line_id')->primary();
            $table->uuid('quotation_id')->index('ql_quotation_id_fk');
            $table->uuid('product_id')->index('ql_product_id_fk');
            $table->uuid('unit_id');
            $table->decimal('quantity', 15, 4);
            $table->decimal('unit_price', 15, 4);
            $table->decimal('discount', 15, 4)->default(0.0000);
            $table->decimal('tax_rate', 5, 2)->default(0.00);
            $table->decimal('total', 15, 4);
            $table->softDeletes();

            $table->foreign('quotation_id')->references('quotation_id')->on('quotations')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
            $table->foreign('unit_id')->references('unit_id')->on('units')->onDelete('cascade');
        });

        // 6. orders
        Schema::create('orders', function (Blueprint $table) {
            $table->uuid('order_id')->primary();
            $table->uuid('tenant_id')->index('orders_tenant_id_idx');
            $table->uuid('branch_id')->index('orders_branch_id_fk');
            $table->uuid('warehouse_id')->nullable()->index('orders_warehouse_id_fk');
            $table->uuid('contact_id')->nullable()->index('orders_contact_id_fk');
            $table->string('ref_no', 100)->nullable();
            $table->date('order_date');
            $table->date('expected_date')->nullable();
            $table->decimal('subtotal', 15, 4)->default(0.0000);
            $table->decimal('discount_value', 15, 4)->default(0.0000);
            $table->decimal('tax_amount', 15, 4)->default(0.0000);
            $table->decimal('total', 15, 4)->default(0.0000);
            $table->tinyInteger('status')->default(1)->comment('1=pending | 2=confirmed | 3=cancelled | 4=converted');
            $table->uuid('converted_to_transaction_id')->nullable();
            $table->text('notes')->nullable();
            $table->uuid('created_by')->index('orders_created_by_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('restrict');
            $table->foreign('warehouse_id')->references('warehouse_id')->on('warehouses')->onDelete('set null');
            $table->foreign('contact_id')->references('contact_id')->on('contacts')->onDelete('set null');
            $table->foreign('converted_to_transaction_id')->references('sales_transaction_id')->on('sales_transactions')->onDelete('set null');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('restrict');
        });

        // 7. order_items
        Schema::create('order_items', function (Blueprint $table) {
            $table->uuid('order_item_id')->primary();
            $table->uuid('order_id')->index('oi_order_id_fk');
            $table->uuid('product_id')->index('oi_product_id_fk');
            $table->uuid('unit_id');
            $table->decimal('quantity', 15, 4);
            $table->decimal('price', 15, 4);
            $table->decimal('discount', 15, 4)->default(0.0000);
            $table->decimal('subtotal', 15, 4);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('order_id')->references('order_id')->on('orders')->onDelete('cascade');
            $table->foreign('product_id')->references('product_id')->on('products')->onDelete('cascade');
            $table->foreign('unit_id')->references('unit_id')->on('units')->onDelete('cascade');
        });

        // 8. transaction_update_histories
        Schema::create('transaction_update_histories', function (Blueprint $table) {
            $table->uuid('transaction_update_history_id')->primary();
            $table->uuid('tenant_id');
            $table->tinyInteger('transaction_type')->comment('1=sales | 2=purchase | 3=inventory');
            $table->uuid('transaction_id');
            $table->decimal('old_total', 15, 4);
            $table->decimal('new_total', 15, 4);
            $table->decimal('old_final_price', 15, 4);
            $table->decimal('new_final_price', 15, 4);
            $table->json('changes_summary')->nullable();
            $table->uuid('updated_by')->index('tuh_updated_by_fk');
            $table->timestamp('created_at')->nullable();

            $table->index(['tenant_id', 'transaction_id'], 'tuh_tenant_transaction_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('updated_by')->references('user_id')->on('users')->onDelete('restrict');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('transaction_update_histories');
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('quotation_lines');
        Schema::dropIfExists('quotations');
        Schema::dropIfExists('sales_transaction_lines');
        Schema::dropIfExists('sales_transactions');
        Schema::dropIfExists('pos_sessions');
        Schema::enableForeignKeyConstraints();
    }
};
