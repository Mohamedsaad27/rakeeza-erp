<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // 1. departments
        Schema::create('departments', function (Blueprint $table) {
            $table->uuid('department_id')->primary();
            $table->uuid('tenant_id')->index('dept_tenant_id_idx');
            $table->uuid('branch_id')->nullable()->index('dept_branch_id_fk');
            $table->uuid('parent_id')->nullable()->index('dept_parent_id_fk');
            $table->string('name_en', 255);
            $table->string('name_ar', 255);
            $table->string('code', 50)->nullable();
            $table->uuid('manager_id')->nullable()->comment('Deferred FK -> employees');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('set null');
            $table->foreign('parent_id')->references('department_id')->on('departments')->onDelete('set null');
        });

        // 2. job_positions
        Schema::create('job_positions', function (Blueprint $table) {
            $table->uuid('job_position_id')->primary();
            $table->uuid('tenant_id')->index('jp_tenant_id_idx');
            $table->uuid('department_id')->nullable()->index('jp_department_id_fk');
            $table->string('title_en', 255);
            $table->string('title_ar', 255);
            $table->text('description_en')->nullable();
            $table->text('description_ar')->nullable();
            $table->decimal('min_salary', 15, 4)->nullable();
            $table->decimal('max_salary', 15, 4)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('department_id')->references('department_id')->on('departments')->onDelete('set null');
        });

        // 3. employees
        Schema::create('employees', function (Blueprint $table) {
            $table->uuid('employee_id')->primary();
            $table->uuid('tenant_id')->index('emp_tenant_id_idx');
            $table->uuid('user_id')->nullable()->index('emp_user_id_fk')->comment('If employee has system login');
            $table->uuid('branch_id')->nullable()->index('emp_branch_id_fk');
            $table->uuid('department_id')->nullable()->index('emp_department_id_fk');
            $table->uuid('job_position_id')->nullable()->index('emp_job_position_id_fk');
            $table->string('employee_code', 50)->nullable();
            $table->string('first_name', 100);
            $table->string('last_name', 100);
            $table->string('national_id', 50)->nullable();
            $table->tinyInteger('gender')->nullable()->comment('1=male | 2=female');
            $table->date('birth_date')->nullable();
            $table->date('hire_date');
            $table->date('termination_date')->nullable();
            $table->tinyInteger('employment_type')->default(1)->comment('1=full_time | 2=part_time | 3=contractor | 4=intern');
            $table->tinyInteger('status')->default(1)->comment('1=active | 2=inactive | 3=on_leave | 4=terminated');
            $table->string('email', 255)->nullable();
            $table->string('phone', 50)->nullable();
            $table->text('address')->nullable();
            $table->uuid('governorate_id')->nullable()->index('emp_governorate_id_foreign');
            $table->uuid('city_id')->nullable()->index('emp_city_id_foreign');
            $table->string('bank_account_no', 100)->nullable();
            $table->string('bank_name', 255)->nullable();
            $table->decimal('base_salary', 15, 4)->default(0.0000);
            $table->tinyInteger('salary_type')->default(1)->comment('1=monthly | 2=daily | 3=hourly');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'employee_code'], 'emp_tenant_code_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('user_id')->references('user_id')->on('users')->onDelete('set null');
            $table->foreign('branch_id')->references('branch_id')->on('branches')->onDelete('set null');
            $table->foreign('department_id')->references('department_id')->on('departments')->onDelete('set null');
            $table->foreign('job_position_id')->references('job_position_id')->on('job_positions')->onDelete('set null');
            $table->foreign('governorate_id')->references('governorate_id')->on('governorates')->onDelete('set null');
            $table->foreign('city_id')->references('city_id')->on('cities')->onDelete('set null');
        });

        // Add deferred foreign key constraints for departments
        Schema::table('departments', function (Blueprint $table) {
            $table->foreign('manager_id')->references('employee_id')->on('employees')->onDelete('set null');
        });

        // 4. attendance_logs
        Schema::create('attendance_logs', function (Blueprint $table) {
            $table->uuid('attendance_log_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('employee_id')->index('att_employee_id_fk');
            $table->date('date');
            $table->timestamp('check_in')->nullable();
            $table->timestamp('check_out')->nullable();
            $table->tinyInteger('status')->default(1)->comment('1=present | 2=absent | 3=late | 4=half_day | 5=leave');
            $table->decimal('overtime_hours', 5, 2)->default(0.00);
            $table->text('note')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'employee_id', 'date'], 'attendance_employee_date_unique');
            $table->index(['tenant_id', 'date'], 'att_tenant_date_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('employee_id')->references('employee_id')->on('employees')->onDelete('cascade');
        });

        // 5. leave_types
        Schema::create('leave_types', function (Blueprint $table) {
            $table->uuid('leave_type_id')->primary();
            $table->uuid('tenant_id')->index('lt_tenant_id_idx');
            $table->string('name_en')->comment('Annual | Sick | Emergency');
            $table->string('name_ar');
            $table->integer('days_allowed')->default(0);
            $table->boolean('is_paid')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // 6. leave_requests
        Schema::create('leave_requests', function (Blueprint $table) {
            $table->uuid('leave_request_id')->primary();
            $table->uuid('tenant_id');
            $table->uuid('employee_id')->index('lr_employee_id_fk');
            $table->uuid('leave_type_id')->index('lr_leave_type_id_fk');
            $table->date('start_date');
            $table->date('end_date');
            $table->integer('days_count');
            $table->text('reason')->nullable();
            $table->tinyInteger('status')->default(1)->comment('1=pending | 2=approved | 3=rejected');
            $table->uuid('approved_by')->nullable()->index('lr_approved_by_fk');
            $table->timestamp('approved_at')->nullable();
            $table->text('rejection_note')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'employee_id'], 'lr_tenant_employee_idx');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('employee_id')->references('employee_id')->on('employees')->onDelete('cascade');
            $table->foreign('leave_type_id')->references('leave_type_id')->on('leave_types')->onDelete('restrict');
            $table->foreign('approved_by')->references('user_id')->on('users')->onDelete('set null');
        });

        // 7. salary_components
        Schema::create('salary_components', function (Blueprint $table) {
            $table->uuid('salary_component_id')->primary();
            $table->uuid('tenant_id')->index('sc_tenant_id_idx');
            $table->string('name_en')->comment('Housing Allowance | Social Insurance');
            $table->string('name_ar');
            $table->tinyInteger('type')->comment('1=allowance | 2=deduction');
            $table->tinyInteger('calculation')->default(1)->comment('1=fixed | 2=percentage');
            $table->decimal('value', 15, 4)->default(0.0000);
            $table->boolean('is_taxable')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
        });

        // 8. employee_salary_components
        Schema::create('employee_salary_components', function (Blueprint $table) {
            $table->uuid('employee_salary_component_id')->primary();
            $table->uuid('employee_id')->index('esc_employee_id_fk');
            $table->uuid('salary_component_id')->index('esc_salary_component_id_fk');
            $table->decimal('value', 15, 4);
            $table->date('effective_from')->nullable();
            $table->date('effective_to')->nullable();
            $table->softDeletes();

            $table->foreign('employee_id')->references('employee_id')->on('employees')->onDelete('cascade');
            $table->foreign('salary_component_id')->references('salary_component_id')->on('salary_components')->onDelete('cascade');
        });

        // 9. payroll_periods
        Schema::create('payroll_periods', function (Blueprint $table) {
            $table->uuid('payroll_period_id')->primary();
            $table->uuid('tenant_id')->index('pp_tenant_id_idx');
            $table->string('name')->nullable();
            $table->date('period_start');
            $table->date('period_end');
            $table->date('payment_date')->nullable();
            $table->tinyInteger('status')->default(1)->comment('1=draft | 2=approved | 3=paid');
            $table->decimal('total_gross', 15, 4)->default(0.0000);
            $table->decimal('total_net', 15, 4)->default(0.0000);
            $table->decimal('total_deductions', 15, 4)->default(0.0000);
            $table->uuid('processed_by')->nullable()->index('pp_processed_by_fk');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('processed_by')->references('user_id')->on('users')->onDelete('set null');
        });

        // 10. payroll_slips
        Schema::create('payroll_slips', function (Blueprint $table) {
            $table->uuid('payroll_slip_id')->primary();
            $table->uuid('tenant_id')->index('ps_tenant_id_idx');
            $table->uuid('payroll_period_id')->index('ps_payroll_period_id_fk');
            $table->uuid('employee_id')->index('ps_employee_id_fk');
            $table->decimal('base_salary', 15, 4);
            $table->decimal('total_allowances', 15, 4)->default(0.0000);
            $table->decimal('total_deductions', 15, 4)->default(0.0000);
            $table->decimal('overtime_pay', 15, 4)->default(0.0000);
            $table->decimal('gross_salary', 15, 4);
            $table->decimal('tax_amount', 15, 4)->default(0.0000);
            $table->decimal('net_salary', 15, 4);
            $table->smallInteger('working_days')->default(0);
            $table->smallInteger('absent_days')->default(0);
            $table->smallInteger('leave_days')->default(0);
            $table->tinyInteger('payment_method')->default(1)->comment('1=bank_transfer | 2=cash | 3=check');
            $table->timestamp('paid_at')->nullable();
            $table->json('lines')->nullable()->comment('Breakdown of salary components');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'payroll_period_id', 'employee_id'], 'payroll_slips_period_employee_unique');
            $table->foreign('tenant_id')->references('tenant_id')->on('tenants')->onDelete('cascade');
            $table->foreign('payroll_period_id')->references('payroll_period_id')->on('payroll_periods')->onDelete('cascade');
            $table->foreign('employee_id')->references('employee_id')->on('employees')->onDelete('cascade');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('payroll_slips');
        Schema::dropIfExists('payroll_periods');
        Schema::dropIfExists('employee_salary_components');
        Schema::dropIfExists('salary_components');
        Schema::dropIfExists('leave_requests');
        Schema::dropIfExists('leave_types');
        Schema::dropIfExists('attendance_logs');
        Schema::dropIfExists('employees');
        Schema::dropIfExists('job_positions');
        Schema::dropIfExists('departments');
        Schema::enableForeignKeyConstraints();
    }
};
