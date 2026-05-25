<?php

namespace App\Modules\Plans\Domain\Enums;

enum BillingCycle: int
{
    case Monthly   = 1;
    case Quarterly = 2;
    case Yearly    = 3;

    public function labelEn(): string
    {
        return match ($this) {
            self::Monthly   => 'Monthly',
            self::Quarterly => 'Quarterly',
            self::Yearly    => 'Yearly',
        };
    }

    public function labelAr(): string
    {
        return match ($this) {
            self::Monthly   => 'شهري',
            self::Quarterly => 'ربع سنوي',
            self::Yearly    => 'سنوي',
        };
    }
}
