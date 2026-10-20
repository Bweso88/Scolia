import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/child_provider.dart';
import '../providers/notifications_provider.dart';

/// En-tête partagé de tous les écrans principaux (Accueil/Devoirs/Suivi/
/// Messages/Agenda), repris du mockup "Scholarly" fourni par l'utilisateur :
/// logo + nom Scolia + rôle, sélecteur d'enfant compact, notifications,
/// avatar. Flottant et translucide au-dessus du contenu qui défile dessous
/// (à placer en haut d'un Stack, avec le contenu scrollable paddé de
/// [AppHeader.hauteur]).
class AppHeader extends StatelessWidget {
  static const double hauteur = 76;

  const AppHeader({super.key});

  String _libelleRole(dynamic user) {
    if (user == null) return '';
    if (user.estAdmin == true) return 'DIRECTION';
    if (user.estEnseignant == true) return 'PROF';
    if (user.estSurveillant == true) return 'VIE SCOLAIRE';
    return 'PARENT';
  }

  static String _initiales(String? nom) {
    if (nom == null || nom.trim().isEmpty) return '?';
    final mots = nom.trim().split(RegExp(r'\s+'));
    return mots.take(2).map((m) => m[0].toUpperCase()).join();
  }

  void _choisirEnfant(BuildContext context) {
    final prov = context.read<ChildProvider>();
    if (prov.enfants.length <= 1) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: prov.enfants.map((e) {
              final actif = prov.selectionne?.id == e.id;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.blue.withOpacity(0.12),
                  child: Text(_initiales(e.nomComplet), style: GoogleFonts.plusJakartaSans(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                title: Text(e.nomComplet, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                subtitle: e.schoolClass != null ? Text(e.schoolClass!.name) : null,
                trailing: actif ? const Icon(Icons.check_circle, color: AppColors.blue) : null,
                onTap: () {
                  context.read<ChildProvider>().selectionner(e);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final enfants = context.watch<ChildProvider>();
    final enfantActif = user?.estParent == true ? enfants.selectionne : null;
    final nonLues = context.watch<NotificationsProvider>().nonLues;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: hauteur,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 20, right: 20, bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.85),
            border: const Border(bottom: BorderSide(color: Color(0x14000000))),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(colors: [AppColors.blue, Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: const Icon(Icons.auto_stories_rounded, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Scolia', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(_libelleRole(user),
                              style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.blue, letterSpacing: 0.4)),
                        ),
                      ],
                    ),
                    if (enfantActif != null)
                      GestureDetector(
                        onTap: () => _choisirEnfant(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                enfantActif.schoolClass != null ? '${enfantActif.firstName} (${enfantActif.schoolClass!.name})' : enfantActif.firstName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                              ),
                            ),
                            if (enfants.enfants.length > 1) ...[
                              const SizedBox(width: 2),
                              const Icon(Icons.expand_more, size: 14, color: AppColors.muted),
                            ],
                          ],
                        ),
                      )
                    else
                      Text('Bonjour, ${user?.name ?? ''}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _BoutonHeader(
                icone: Icons.notifications_outlined,
                badge: nonLues > 0,
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/profil'),
                child: Container(
                  width: 40, height: 40,
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(colors: [AppColors.blue, Color(0xFF6366F1), Color(0xFFEC4899)]),
                  ),
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(12.5)),
                    child: Center(
                      child: Text(_initiales(user?.name), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoutonHeader extends StatelessWidget {
  final IconData icone;
  final bool badge;
  final VoidCallback onTap;
  const _BoutonHeader({required this.icone, required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Stack(
          children: [
            Center(child: Icon(icone, size: 20, color: AppColors.body)),
            if (badge)
              Positioned(
                top: 9, right: 9,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 1.5)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
