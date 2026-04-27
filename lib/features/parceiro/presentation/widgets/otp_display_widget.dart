import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class OtpDisplayWidget extends StatefulWidget {
  final String token;
  final DateTime expiresAt;
  final VoidCallback? onExpired;

  const OtpDisplayWidget({
    super.key,
    required this.token,
    required this.expiresAt,
    this.onExpired,
  });

  @override
  State<OtpDisplayWidget> createState() => _OtpDisplayWidgetState();
}

class _OtpDisplayWidgetState extends State<OtpDisplayWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final remaining = widget.expiresAt.difference(now);
    if (remaining.isNegative) {
      _timer?.cancel();
      setState(() => _remaining = Duration.zero);
      widget.onExpired?.call();
    } else {
      setState(() => _remaining = remaining);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining == Duration.zero;
    final isLow = _remaining.inSeconds < 60;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Seu Token',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6D7F95),
            ),
          ),
          const SizedBox(height: 16),
          // OTP digits
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.token.split('').map((digit) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 44,
                height: 56,
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.grey.withValues(alpha: 0.1)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isExpired
                        ? Colors.grey.withValues(alpha: 0.3)
                        : AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    digit,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isExpired ? Colors.grey : AppTheme.primaryColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (isExpired
                      ? Colors.red
                      : isLow
                          ? Colors.orange
                          : AppTheme.primaryColor)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isExpired ? Icons.timer_off : Icons.timer_outlined,
                  size: 16,
                  color: isExpired
                      ? Colors.red
                      : isLow
                          ? Colors.orange
                          : AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isExpired ? 'Expirado' : _formatDuration(_remaining),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isExpired
                        ? Colors.red
                        : isLow
                            ? Colors.orange
                            : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
