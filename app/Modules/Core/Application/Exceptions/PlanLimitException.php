<?php

namespace App\Modules\Core\Application\Exceptions;

class PlanLimitException extends BaseException
{
    public function __construct(
        private readonly string $limitKey,
        private readonly int $current,
        private readonly int $allowed,
    ) {
        parent::__construct(
            "Plan limit reached: {$limitKey}",
            402,
        );
    }

    public function getLimitKey(): string
    {
        return $this->limitKey;
    }

    public function getCurrent(): int
    {
        return $this->current;
    }

    public function getAllowed(): int
    {
        return $this->allowed;
    }

    protected function getDefaultMessage(): string
    {
        return "Plan limit reached: {$this->limitKey}";
    }

    protected function getDefaultStatusCode(): int
    {
        return 402;
    }
}
