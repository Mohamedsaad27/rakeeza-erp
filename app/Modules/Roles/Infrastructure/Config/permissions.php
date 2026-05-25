<?php

return [
    'users' => [
        'label_en' => 'Users',
        'label_ar' => 'المستخدمون',
        'permissions' => [
            'user.view'   => ['label_en' => 'View Users',   'label_ar' => 'عرض المستخدمين'],
            'user.create' => ['label_en' => 'Create Users', 'label_ar' => 'إنشاء مستخدم'],
            'user.update' => ['label_en' => 'Update Users', 'label_ar' => 'تعديل المستخدمين'],
            'user.delete' => ['label_en' => 'Delete Users', 'label_ar' => 'حذف المستخدمين'],
        ],
    ],
    'roles' => [
        'label_en' => 'Roles & Permissions',
        'label_ar' => 'الأدوار والصلاحيات',
        'permissions' => [
            'role.view'         => ['label_en' => 'View Roles',              'label_ar' => 'عرض الأدوار'],
            'role.create'       => ['label_en' => 'Create Roles',            'label_ar' => 'إنشاء دور'],
            'role.update'       => ['label_en' => 'Update Roles',            'label_ar' => 'تعديل الأدوار'],
            'role.delete'       => ['label_en' => 'Delete Roles',            'label_ar' => 'حذف الأدوار'],
            'permission.view'   => ['label_en' => 'View Permissions',        'label_ar' => 'عرض الصلاحيات'],
            'permission.assign' => ['label_en' => 'Assign Permissions',      'label_ar' => 'تعيين الصلاحيات'],
        ],
    ],
    'contacts' => [
        'label_en' => 'Contacts (CRM)',
        'label_ar' => 'جهات الاتصال',
        'permissions' => [
            'contact.view'   => ['label_en' => 'View Contacts',   'label_ar' => 'عرض جهات الاتصال'],
            'contact.create' => ['label_en' => 'Create Contacts', 'label_ar' => 'إنشاء جهة اتصال'],
            'contact.update' => ['label_en' => 'Update Contacts', 'label_ar' => 'تعديل جهات الاتصال'],
            'contact.delete' => ['label_en' => 'Delete Contacts', 'label_ar' => 'حذف جهات الاتصال'],
        ],
    ],
    'products' => [
        'label_en' => 'Products',
        'label_ar' => 'المنتجات',
        'permissions' => [
            'product.view'   => ['label_en' => 'View Products',   'label_ar' => 'عرض المنتجات'],
            'product.create' => ['label_en' => 'Create Products', 'label_ar' => 'إنشاء منتج'],
            'product.update' => ['label_en' => 'Update Products', 'label_ar' => 'تعديل المنتجات'],
            'product.delete' => ['label_en' => 'Delete Products', 'label_ar' => 'حذف المنتجات'],
        ],
    ],
    'inventory' => [
        'label_en' => 'Inventory',
        'label_ar' => 'المخزون',
        'permissions' => [
            'inventory.view'     => ['label_en' => 'View Inventory',     'label_ar' => 'عرض المخزون'],
            'inventory.adjust'     => ['label_en' => 'Adjust Stock',       'label_ar' => 'تعديل المخزون'],
            'inventory.transfer'   => ['label_en' => 'Transfer Stock',     'label_ar' => 'نقل المخزون'],
        ],
    ],
    'sales' => [
        'label_en' => 'Sales',
        'label_ar' => 'المبيعات',
        'permissions' => [
            'sale.view'   => ['label_en' => 'View Sales',   'label_ar' => 'عرض المبيعات'],
            'sale.create' => ['label_en' => 'Create Sales', 'label_ar' => 'إنشاء فاتورة مبيعات'],
            'sale.delete' => ['label_en' => 'Delete Sales', 'label_ar' => 'حذف المبيعات'],
            'sale.return' => ['label_en' => 'Sales Returns', 'label_ar' => 'مرتجعات المبيعات'],
        ],
    ],
    'purchasing' => [
        'label_en' => 'Purchasing',
        'label_ar' => 'المشتريات',
        'permissions' => [
            'purchase.view'   => ['label_en' => 'View Purchases',   'label_ar' => 'عرض المشتريات'],
            'purchase.create' => ['label_en' => 'Create Purchases', 'label_ar' => 'إنشاء فاتورة مشتريات'],
            'purchase.delete' => ['label_en' => 'Delete Purchases', 'label_ar' => 'حذف المشتريات'],
            'purchase.return' => ['label_en' => 'Purchase Returns', 'label_ar' => 'مرتجعات المشتريات'],
        ],
    ],
    'finance' => [
        'label_en' => 'Finance',
        'label_ar' => 'المالية',
        'permissions' => [
            'finance.view'   => ['label_en' => 'View Finance',    'label_ar' => 'عرض المالية'],
            'finance.manage' => ['label_en' => 'Manage Finance',  'label_ar' => 'إدارة المالية'],
        ],
    ],
    'payments' => [
        'label_en' => 'Payments',
        'label_ar' => 'المدفوعات',
        'permissions' => [
            'payment.view'   => ['label_en' => 'View Payments',   'label_ar' => 'عرض المدفوعات'],
            'payment.create' => ['label_en' => 'Create Payments', 'label_ar' => 'إنشاء دفعة'],
        ],
    ],
    'expenses' => [
        'label_en' => 'Expenses',
        'label_ar' => 'المصروفات',
        'permissions' => [
            'expense.view'   => ['label_en' => 'View Expenses',   'label_ar' => 'عرض المصروفات'],
            'expense.create' => ['label_en' => 'Create Expenses', 'label_ar' => 'إنشاء مصروف'],
        ],
    ],
    'hr' => [
        'label_en' => 'Human Resources',
        'label_ar' => 'الموارد البشرية',
        'permissions' => [
            'hr.view'            => ['label_en' => 'View HR',             'label_ar' => 'عرض الموارد البشرية'],
            'employees.manage'   => ['label_en' => 'Manage Employees',    'label_ar' => 'إدارة الموظفين'],
            'payroll.manage'     => ['label_en' => 'Manage Payroll',      'label_ar' => 'إدارة الرواتب'],
        ],
    ],
    'reports' => [
        'label_en' => 'Reports',
        'label_ar' => 'التقارير',
        'permissions' => [
            'report.view' => ['label_en' => 'View Reports', 'label_ar' => 'عرض التقارير'],
        ],
    ],
    'settings' => [
        'label_en' => 'Settings',
        'label_ar' => 'الإعدادات',
        'permissions' => [
            'settings.manage' => ['label_en' => 'Manage Settings', 'label_ar' => 'إدارة الإعدادات'],
        ],
    ],
    'pos' => [
        'label_en' => 'Point of Sale',
        'label_ar' => 'نقطة البيع',
        'permissions' => [
            'pos.access' => ['label_en' => 'Access POS', 'label_ar' => 'الوصول لنقطة البيع'],
        ],
    ],
    'dashboard' => [
        'label_en' => 'Dashboard',
        'label_ar' => 'لوحة التحكم',
        'permissions' => [
            'dashboard.view' => ['label_en' => 'View Dashboard', 'label_ar' => 'عرض لوحة التحكم'],
        ],
    ],
    'audit' => [
        'label_en' => 'Audit Log',
        'label_ar' => 'سجل التدقيق',
        'permissions' => [
            'audit.view' => ['label_en' => 'View Audit Logs', 'label_ar' => 'عرض سجل التدقيق'],
        ],
    ],
];
