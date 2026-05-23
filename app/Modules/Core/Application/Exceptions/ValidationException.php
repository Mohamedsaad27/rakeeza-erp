<?php

namespace App\Modules\Core\Application\Exceptions;

use Illuminate\Validation\ValidationException as LaravelValidationException;

class ValidationException extends BaseException
{
    private array $errors;

    public function __construct(LaravelValidationException $e)
    {
        $this->errors = $e->errors();
        parent::__construct($e->getMessage(), 422);
    }

    public function getErrors(): array
    {
        return $this->errors;
    }

    protected function getDefaultMessage(): string
    {
        return __('messages.validation_failed');
    }

    protected function getDefaultStatusCode(): int
    {
        return 422;
    }
}
