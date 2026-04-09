import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? sousTitre;
  final IconData icone;
  final VoidCallback? onAction;
  final String? libelleAction;

  const EmptyState({
    super.key,
    required this.message,
    this.sousTitre,
    this.icone = Icons.inbox_outlined,
    this.onAction,
    this.libelleAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 36, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.body,
              ),
              textAlign: TextAlign.center,
            ),
            if (sousTitre != null) ...[
              const SizedBox(height: 8),
              Text(
                sousTitre!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                child: Text(libelleAction ?? 'Actualiser'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
