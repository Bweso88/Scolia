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
                (user?.prenom?.isNotEmpty == true ? user!.prenom![0] : '?').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.white),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user?.nomComplet ?? '—',
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(8)),
              child: Text(
                _libelleRole(user?.role),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              child: Column(
                children: [
                  _LigneProfil(icone: Icons.phone_outlined,  label: 'Téléphone', valeur: user?.telephone ?? '—'),
                  const Divider(height: 1, indent: 56),
                  _LigneProfil(icone: Icons.school_outlined, label: 'Rôle', valeur: _libelleRole(user?.role)),
                ],
              ),
            ),
            const SizedBox(height: 30),
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

  String _libelleRole(String? role) {
    switch (role) {
      case 'parent':       return 'Parent';
      case 'teacher':      return 'Enseignant';
      case 'school_admin': return 'Administrateur';
      case 'super_admin':  return 'Super administrateur';
      default:             return role ?? '—';
    }
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
      context.go('/auth/telephone');
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
