<?php

namespace App\Modules\Roles\Infrastructure\Database\Seeders;

use App\Modules\Roles\Infrastructure\Database\Models\Permission;
use App\Modules\Roles\Infrastructure\Database\Models\Role;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DefaultRolesSeeder extends Seeder
{
    public function run(string $tenantId): void
    {
        $allPermissions = Permission::query()->whereNull('tenant_id')->pluck('permission_id', 'name');

        $roles = [
            'admin' => [
                'name_en' => 'Administrator',
                'name_ar' => 'مدير النظام',
                'permissions' => $allPermissions->keys()->all(),
            ],
            'manager' => [
                'name_en' => 'Manager',
                'name_ar' => 'مدير',
                'permissions' => $this->matchPermissions($allPermissions, [
                    'contact.', 'product.', 'inventory.', 'sale.', 'purchase.',
                    'payment.', 'expense.', 'report.view', 'dashboard.view',
                ]),
            ],
            'sales' => [
                'name_en' => 'Sales',
                'name_ar' => 'مبيعات',
                'permissions' => $this->matchPermissions($allPermissions, [
                    'contact.view', 'product.view', 'sale.', 'payment.',
                ]),
            ],
            'purchaser' => [
                'name_en' => 'Purchaser',
                'name_ar' => 'مشتريات',
                'permissions' => $this->matchPermissions($allPermissions, [
                    'contact.view', 'product.view', 'purchase.', 'payment.',
                ]),
            ],
            'accountant' => [
                'name_en' => 'Accountant',
                'name_ar' => 'محاسب',
                'permissions' => $this->matchPermissions($allPermissions, [
                    'finance.', 'payment.', 'expense.', 'report.view',
                ]),
            ],
            'cashier' => [
                'name_en' => 'Cashier',
                'name_ar' => 'أمين صندوق',
                'permissions' => $this->matchPermissions($allPermissions, [
                    'pos.access', 'payment.', 'contact.view',
                ]),
            ],
            'hr' => [
                'name_en' => 'HR',
                'name_ar' => 'الموارد البشرية',
                'permissions' => $this->matchPermissions($allPermissions, [
                    'hr.', 'employees.', 'payroll.',
                ]),
            ],
            'viewer' => [
                'name_en' => 'Viewer',
                'name_ar' => 'مشاهد',
                'permissions' => $this->matchPermissions($allPermissions, ['.view']),
            ],
        ];

        foreach ($roles as $key => $roleData) {
            $role = Role::withoutGlobalScopes()->updateOrCreate(
                [
                    'tenant_id'  => $tenantId,
                    'name'       => $key,
                    'guard_name' => 'api',
                ],
                [
                    'name_en'    => $roleData['name_en'],
                    'name_ar'    => $roleData['name_ar'],
                    'is_system'  => true,
                    'is_active'  => true,
                ],
            );

            $permissionIds = collect($roleData['permissions'])
                ->map(fn (string $name) => $allPermissions->get($name))
                ->filter()
                ->values()
                ->all();

            $role->syncPermissions($permissionIds);

            DB::table('role_has_permissions')
                ->where('role_id', $role->role_id)
                ->update(['tenant_id' => $tenantId]);
        }
    }

    protected function matchPermissions($allPermissions, array $patterns): array
    {
        return $allPermissions->keys()->filter(function (string $name) use ($patterns) {
            foreach ($patterns as $pattern) {
                if (str_ends_with($pattern, '.')) {
                    if (str_starts_with($name, $pattern)) {
                        return true;
                    }
                } elseif (str_starts_with($pattern, '.')) {
                    if (str_ends_with($name, $pattern)) {
                        return true;
                    }
                } elseif ($name === $pattern || str_starts_with($name, $pattern)) {
                    return true;
                }
            }

            return false;
        })->values()->all();
    }
}
