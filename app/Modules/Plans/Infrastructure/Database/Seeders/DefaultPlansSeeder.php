<?php

namespace App\Modules\Plans\Infrastructure\Database\Seeders;

use App\Modules\Features\Infrastructure\Database\Models\Feature;
use App\Modules\Plans\Infrastructure\Database\Models\Plan;
use App\Modules\Plans\Infrastructure\Persistence\Repositories\PlanRepository;
use Illuminate\Database\Seeder;

class DefaultPlansSeeder extends Seeder
{
    public function run(): void
    {
        $repository = app(PlanRepository::class);

        $plans = [
            'starter' => [
                'name_en' => 'Starter',
                'name_ar' => 'البداية',
                'price'   => 299.0000,
                'billing_cycle' => 1,
                'trial_days'    => 14,
                'max_users'     => 3,
                'max_branches'    => 1,
                'features'      => ['crm', 'sales', 'reports'],
                'limits'        => ['max_products' => 100, 'max_warehouses' => 1],
            ],
            'professional' => [
                'name_en' => 'Professional',
                'name_ar' => 'احترافي',
                'price'   => 799.0000,
                'billing_cycle' => 1,
                'trial_days'    => 14,
                'max_users'     => 15,
                'max_branches'    => 3,
                'features'      => ['crm', 'sales', 'purchasing', 'inventory', 'finance', 'reports', 'multi_branch'],
                'limits'        => ['max_products' => 1000, 'max_warehouses' => 5],
            ],
            'enterprise' => [
                'name_en' => 'Enterprise',
                'name_ar' => 'المؤسسات',
                'price'   => 1999.0000,
                'billing_cycle' => 1,
                'trial_days'    => 30,
                'max_users'     => null,
                'max_branches'    => null,
                'features'      => ['crm', 'sales', 'purchasing', 'inventory', 'finance', 'hr', 'pos', 'reports', 'multi_branch', 'api_access'],
                'limits'        => ['max_products' => 50000, 'max_warehouses' => 50],
            ],
        ];

        $featureMap = Feature::query()->pluck('feature_id', 'code');

        foreach ($plans as $key => $planData) {
            $plan = Plan::query()->updateOrCreate(
                ['name_en' => $planData['name_en']],
                [
                    'name_ar'       => $planData['name_ar'],
                    'price'         => $planData['price'],
                    'billing_cycle' => $planData['billing_cycle'],
                    'trial_days'    => $planData['trial_days'],
                    'max_users'     => $planData['max_users'],
                    'max_branches'  => $planData['max_branches'],
                    'is_active'     => true,
                ],
            );

            $sync = [];
            foreach ($planData['features'] as $code) {
                if ($featureMap->has($code)) {
                    $sync[$featureMap[$code]] = true;
                }
            }

            $repository->syncFeatures($plan, $sync);
            $repository->syncLimits($plan, $planData['limits']);
        }
    }
}
