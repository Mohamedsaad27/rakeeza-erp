<?php

namespace App\Modules\Core\Infrastructure\Traits;

use Illuminate\Support\Str;

trait HasUuid
{
    public static function bootHasUuid(): void
    {
        static::creating(function ($model) {
            $primaryKey = $model->getKeyName();

            if (empty($model->{$primaryKey})) {
                $model->{$primaryKey} = (string) Str::uuid();
            }
        });
    }

    public function getIncrementing(): bool
    {
        return false;
    }

    public function getKeyType(): string
    {
        return 'string';
    }
}
