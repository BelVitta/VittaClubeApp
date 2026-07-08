import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../primary_button.dart';

/// Widget genérico para exibir estados de erro
class ErrorStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final bool showButton;

  const ErrorStateWidget({
    super.key,
    this.icon = Icons.error_outline,
    required this.title,
    required this.message,
    this.buttonText = 'Tentar Novamente',
    required this.onButtonPressed,
    this.showButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration placeholder
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF031535),
                letterSpacing: 0.12,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 9),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D7F95),
                letterSpacing: 0.07,
                height: 1.07,
              ),
            ),

            if (showButton) ...[
              const SizedBox(height: 16),
              // Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: buttonText,
                  onPressed: onButtonPressed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
