import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

/// Un parent avec des enfants dans plusieurs écoles choisit ici laquelle
/// consulter (docs/PRODUCT_ARCHITECTURE.md §9 et §12), sans ressaisir son
/// mot de passe : chaque école garde sa propre identité visuelle.
class SelectionEcoleScreen extends StatefulWidget {
  const SelectionEcoleScreen({super.key});

  @override
  State<SelectionEcoleScreen> createState() => _SelectionEcoleScreenState();
}

class _SelectionEcoleScreenState extends State<SelectionEcoleScreen> {
  bool _bascule = false;

  Future<void> _choisir(int userId) async {
    setState(() => _bascule = true);
    try {
      await context.read<AuthProvider>().basculerContexte(userId);
      if (mounted) context.go('/accueil');
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _bascule = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final contexts = auth.contexts;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Choisissez une école',
                  style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.white)),
              const SizedBox(height: 8),
              Text('Votre compte est relié à plusieurs établissements.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.white.withOpacity(0.7))),
              const SizedBox(height: 28),
              if (_bascule)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.amber)),
                )
              else
                ...contexts.map((c) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.light,
                          child: Icon(Icons.school_outlined, color: AppColors.navy),
                        ),
                        title: Text(c.tenantName ?? 'École',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.navy)),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                        onTap: () => _choisir(c.userId),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
