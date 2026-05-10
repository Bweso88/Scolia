import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/liaison_provider.dart';
import '../../providers/notes_provider.dart';
import '../../config/theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/api_service.dart';
import '../../models/dossier.dart';
import '../../models/eleve.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Dossier> _dossiers = [];
  List<Eleve>   _eleves   = [];
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _charger();
      context.read<LiaisonProvider>().charger(recharger: true);
    });
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    final user = context.read<AuthProvider>().user;
    try {
      if (user?.estEnseignant == true) {
        final data = await apiService.get('/eleves');
        setState(() {
          _eleves = (data['items'] as List)
              .map((e) => Eleve.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      } else {
        final data = await apiService.get('/dossiers');
        setState(() {
          _dossiers = (data['dossiers'] as List)
              .map((e) => Dossier.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
    } finally {
      setState(() => _charge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, ${user?.prenom ?? ''}',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
            Text('Bienvenue sur Scolia',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.white.withOpacity(0.7))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppColors.white),
            onPressed: () => context.push('/profil'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user?.estParent == true) ...[
                Text('Mes enfants', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 12),
                if (_charge)
                  const Center(child: CircularProgressIndicator())
                else if (_dossiers.isEmpty)
                  _carteVide('Aucun enfant lié', 'Contactez l\'école pour activer votre dossier.', Icons.child_care_outlined)
                else
                  ..._dossiers.map((d) => _CarteEnfant(dossier: d)),
                const SizedBox(height: 20),
              ],
              if (user?.estEnseignant == true) ...[
                Text('Ma classe', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 12),
                _CarteClasse(nbEleves: _eleves.length, classeNom: _eleves.isNotEmpty ? (_eleves.first.classeNom ?? '') : ''),
                const SizedBox(height: 20),
              ],
              Text('Accès rapide', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
              const SizedBox(height: 12),
              if (user?.estEnseignant == true)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _CarteAcces(icone: Icons.groups_outlined,         titre: 'Ma classe',   couleur: AppColors.navy,   onTap: () => context.go('/teacher/ma-classe')),
                    _CarteAcces(icone: Icons.add_chart_outlined,      titre: 'Saisir note', couleur: AppColors.green,  onTap: () => context.push('/notes/saisir')),
                    _CarteAcces(icone: Icons.menu_book_outlined,      titre: 'Liaison',     couleur: AppColors.blue,   onTap: () => context.go('/liaison')),
                    _CarteAcces(icone: Icons.comment_outlined,        titre: 'Remarques',   couleur: AppColors.purple, onTap: () => context.go('/remarques')),
                    _CarteAcces(icone: Icons.calendar_today_outlined, titre: 'Calendrier',  couleur: AppColors.amber,  onTap: () => context.go('/calendrier')),
                    _CarteAcces(icone: Icons.notifications_outlined,  titre: 'Notifications', couleur: AppColors.orange, onTap: () => context.go('/notifications')),
                  ],
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _CarteAcces(icone: Icons.menu_book_outlined,                 titre: 'Liaison',       couleur: AppColors.blue,   onTap: () => context.go('/liaison')),
                    _CarteAcces(icone: Icons.comment_outlined,                   titre: 'Remarques',     couleur: AppColors.purple, onTap: () => context.go('/remarques')),
                    _CarteAcces(icone: Icons.bar_chart_outlined,                 titre: 'Notes',         couleur: AppColors.green,  onTap: () => context.go('/notes')),
                    _CarteAcces(icone: Icons.account_balance_wallet_outlined,    titre: 'Frais',         couleur: AppColors.orange, onTap: () => context.go('/frais')),
                    _CarteAcces(icone: Icons.calendar_today_outlined,            titre: 'Calendrier',    couleur: AppColors.navy,   onTap: () => context.go('/calendrier')),
                    _CarteAcces(icone: Icons.notifications_outlined,             titre: 'Notifications', couleur: AppColors.amber,  onTap: () => context.go('/notifications')),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(indexActuel: 0),
    );
  }

  Widget _carteVide(String titre, String sous, IconData icone) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icone, color: AppColors.muted, size: 32),
            const SizedBox(height: 8),
            Text(titre, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.body)),
            Text(sous, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _CarteClasse extends StatelessWidget {
  final int nbEleves;
  final String classeNom;
  const _CarteClasse({required this.nbEleves, required this.classeNom});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/teacher/ma-classe'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.navy.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.groups_outlined, color: AppColors.navy, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(classeNom.isNotEmpty ? classeNom : 'Ma classe',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.navy)),
                    Text('$nbEleves élève${nbEleves > 1 ? 's' : ''}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarteEnfant extends StatelessWidget {
  final Dossier dossier;
  const _CarteEnfant({required this.dossier});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.light,
          child: Text(
            dossier.prenom.isNotEmpty ? dossier.prenom[0].toUpperCase() : '?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
        ),
        title: Text(dossier.nomComplet, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.navy)),
        subtitle: Text(dossier.classeNom ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: dossier.actif ? AppColors.green.withOpacity(0.1) : AppColors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            dossier.actif ? 'Actif' : 'Inactif',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: dossier.actif ? AppColors.green : AppColors.red,
            ),
          ),
        ),
      ),
    );
  }
}

class _CarteAcces extends StatelessWidget {
  final IconData icone;
  final String titre;
  final Color couleur;
  final VoidCallback onTap;

  const _CarteAcces({required this.icone, required this.titre, required this.couleur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: couleur, size: 28),
              const SizedBox(height: 8),
              Text(titre, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.body)),
            ],
          ),
        ),
      ),
    );
  }
}
