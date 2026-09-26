import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final branding = user?.tenant;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.navy,
              child: Text(
                (user?.name.isNotEmpty == true ? user!.name[0] : '?').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.white),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user?.name ?? '—',
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(8)),
              child: Text(
                _libelleRoles(user?.roles ?? const []),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              child: Column(
                children: [
                  _LigneProfil(icone: Icons.mail_outline,  label: 'E-mail', valeur: user?.email ?? '—'),
                  if (user?.phone != null) ...[
                    const Divider(height: 1, indent: 56),
                    _LigneProfil(icone: Icons.phone_outlined, label: 'Téléphone', valeur: user!.phone!),
                  ],
                  if (branding != null) ...[
                    const Divider(height: 1, indent: 56),
                    _LigneProfil(icone: Icons.school_outlined, label: 'École', valeur: branding.displayName),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.navy),
                label: Text('Préférences de notifications', style: GoogleFonts.plusJakartaSans(color: AppColors.navy, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.push('/profil/notifications'),
              ),
            ),
            const SizedBox(height: 12),
            if (auth.aPlusieursEcoles)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz, color: AppColors.navy),
                    label: Text('Changer d\'école', style: GoogleFonts.plusJakartaSans(color: AppColors.navy, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => context.push('/auth/ecole'),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AppColors.red),
                label: Text('Se déconnecter', style: GoogleFonts.plusJakartaSans(color: AppColors.red, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.red),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _confirmerDeconnexion(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _libelleRoles(List<String> roles) {
    const libelles = {
      'parent': 'Parent',
      'teacher': 'Enseignant',
      'school_admin': 'Administrateur',
      'direction': 'Direction',
      'surveillant': 'Surveillant',
    };
    if (roles.isEmpty) return '—';
    return roles.map((r) => libelles[r] ?? r).join(', ');
  }

  Future<void> _confirmerDeconnexion(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Déconnexion', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Voulez-vous vraiment vous déconnecter ?', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Déconnecter', style: GoogleFonts.plusJakartaSans(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirme == true && context.mounted) {
      await context.read<AuthProvider>().deconnexion();
      context.go('/auth/connexion');
    }
  }
}

class _LigneProfil extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;

  const _LigneProfil({required this.icone, required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone, color: AppColors.navy, size: 20),
      title: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
      subtitle: Text(valeur, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.body)),
    );
  }
}
