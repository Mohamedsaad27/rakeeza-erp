<?php

namespace App\Modules\Core\Application\Exceptions;

use Exception;

abstract class BaseException extends Exception
{
    protected int $statusCode;

    public function __construct(string $message = null, int $statusCode = null, Exception $previous = null)
    {
        $message = $message ?: $this->getDefaultMessage();
        $statusCode = $statusCode ?: $this->getDefaultStatusCode();

        $this->statusCode = $statusCode;

        parent::__construct($message, $statusCode, $previous);
    }

    public function getStatusCode(): int
    {
        return $this->statusCode;
    }

    abstract protected function getDefaultMessage(): string;
    abstract protected function getDefaultStatusCode(): int;
}
