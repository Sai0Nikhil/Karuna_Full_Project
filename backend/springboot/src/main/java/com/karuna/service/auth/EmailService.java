package com.karuna.service.auth;

import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendEmailVerification(String email, String name, String token) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom("reachsainikhil@gmail.com");
            message.setTo(email);
            message.setSubject("Karuṇā — Verify Your Email Address");
            message.setText("Dear " + name + ",\n\n" +
                    "Thank you for registering with Karuṇā Rescue Network!\n\n" +
                    "Please verify your email using the token below:\n" +
                    token + "\n\n" +
                    "Best regards,\n" +
                    "Karuṇā Team");
            mailSender.send(message);
            System.out.println("Email verification token sent to " + email);
        } catch (Exception e) {
            System.err.println("Failed to send email verification: " + e.getMessage());
        }
    }

    public void sendPasswordReset(String email, String name, String token) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom("reachsainikhil@gmail.com");
            message.setTo(email);
            message.setSubject("Karuṇā — Reset Your Password");
            message.setText("Dear " + name + ",\n\n" +
                    "We received a request to reset your password for your Karuṇā account.\n\n" +
                    "Please copy the reset token below to reset your password:\n" +
                    token + "\n\n" +
                    "If you did not request this password reset, please ignore this email.\n\n" +
                    "Best regards,\n" +
                    "Karuṇā Team");
            mailSender.send(message);
            System.out.println("Password reset token sent to " + email);
        } catch (Exception e) {
            System.err.println("Failed to send password reset email: " + e.getMessage());
        }
    }
}
