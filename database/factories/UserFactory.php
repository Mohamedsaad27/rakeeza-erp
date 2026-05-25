<?php

namespace Database\Factories;

use App\Modules\Auth\Infrastructure\Database\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected $model = User::class;

    protected static ?string $password;

    public function definition(): array
    {
        return [
            'tenant_id'   => null,
            'name'        => fake()->name(),
            'username'    => fake()->unique()->userName(),
            'email'       => fake()->unique()->safeEmail(),
            'phone'       => null,
            'password'    => static::$password ??= Hash::make('password'),
            'is_active'   => true,
            'verified_at' => now(),
        ];
    }

    public function platformAdmin(): static
    {
        return $this->state(fn (array $attributes) => [
            'tenant_id' => null,
        ]);
    }

    public function forTenant(string $tenantId): static
    {
        return $this->state(fn (array $attributes) => [
            'tenant_id' => $tenantId,
        ]);
    }

    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'verified_at' => null,
        ]);
    }
}
