<?php

namespace App\Modules\Auth\Infrastructure\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class PasswordResetNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        private readonly string $token,
        private readonly ?string $tenantId = null,
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $resetUrl = config('app.frontend_url', config('app.url'))
            . '/reset-password?token=' . urlencode($this->token)
            . '&email=' . urlencode($notifiable->email);

        if ($this->tenantId) {
            $resetUrl .= '&tenant_id=' . urlencode($this->tenantId);
        }

        return (new MailMessage)
            ->subject(__('auth.reset_password_subject'))
            ->line(__('auth.reset_password_line'))
            ->action(__('auth.reset_password_action'), $resetUrl)
            ->line(__('auth.reset_password_expiry'));
    }
}
