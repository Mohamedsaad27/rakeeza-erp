<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. report_templates
        Schema::create('report_templates', function (Blueprint $table) {
            $table->uuid('report_template_id')->primary();
            $table->uuid('tenant_id')->index('rt_tenant_id_idx');
            $table->string('name_en');
            $table->string('name_ar');
            $table->string('module', 100)->nullable()->comment('sales | inventory | finance | hr');
            $table->json('filters')->nullable();
            $table->json('columns')->nullable();
            $table->boolean('is_shared')->default(false);
            $table->uuid('created_by')->index('rt_created_by_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('cascade');
        });

        // 2. scheduled_reports
        Schema::create('scheduled_reports', function (Blueprint $table) {
            $table->uuid('scheduled_report_id')->primary();
            $table->uuid('tenant_id')->index('sr_tenant_id_idx');
            $table->uuid('report_template_id')->nullable()->index('sr_report_template_id_fk');
            $table->string('name_en');
            $table->string('name_ar');
            $table->tinyInteger('frequency')->default(1)->comment('1=daily | 2=weekly | 3=monthly');
            $table->time('send_at')->nullable();
            $table->json('recipients')->nullable();
            $table->tinyInteger('format')->default(1)->comment('1=pdf | 2=excel | 3=csv');
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_sent_at')->nullable();
            $table->uuid('created_by')->index('sr_created_by_foreign');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('report_template_id')->references('report_template_id')->on('report_templates')->onDelete('set null');
            $table->foreign('created_by')->references('user_id')->on('users')->onDelete('cascade');
        });

        // 3. kpi_snapshots
        Schema::create('kpi_snapshots', function (Blueprint $table) {
            $table->uuid('kpi_snapshot_id')->primary();
            $table->uuid('tenant_id');
            $table->date('date');
            $table->string('metric', 100)->comment('total_sales | gross_profit | new_customers | inventory_value');
            $table->decimal('value', 20, 4);
            $table->uuid('branch_id')->nullable()->index('kpi_branch_id_fk');
            $table->timestamp('created_at')->nullable();

            $table->unique(['tenant_id', 'date', 'metric', 'branch_id'], 'kpi_tenant_date_metric_branch_unique');
            $table->index(['tenant_id', 'metric', 'date'], 'kpi_tenant_metric_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('set null');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('kpi_snapshots');
        Schema::dropIfExists('scheduled_reports');
        Schema::dropIfExists('report_templates');
        Schema::enableForeignKeyConstraints();
    }
};
