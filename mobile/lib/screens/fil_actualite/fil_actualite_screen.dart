import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/fil_item.dart';
import '../../providers/child_provider.dart';
import '../../services/children_service.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/child_selector.dart';
import '../../widgets/empty_state.dart';

/// Fil d'actualité de l'espace parent : récap chronologique des annonces de
/// l'école et des éléments récents concernant l'enfant sélectionné
/// (comportement, devoirs, absences) — additif au menu "Accès rapide",
/// pas un remplacement (docs/PRODUCT_ARCHITECTURE.md).
class FilActualiteScreen extends StatefulWidget {
  const FilActualiteScreen({super.key});

  @override
  State<FilActualiteScreen> createState() => _FilActualiteScreenState();
}

class _FilActualiteScreenState extends State<FilActualiteScreen> {
  final _service = ChildrenService();
  List<FilItem> _items = [];
  bool _charge = false;
  int? _dernierEnfantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    final enfant = context.read<ChildProvider>().selectionne;
    if (enfant == null) return;
    setState(() => _charge = true);
    try {
      _items = await _service.getFil(enfant.id);
      _dernierEnfantId = enfant.id;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  static const _icones = {
    'annonce': Icons.campaign_outlined,
    'comportement': Icons.comment_outlined,
    'devoir': Icons.assignment_outlined,
    'absence': Icons.event_busy_outlined,
  };

  static const _couleurs = {
    'annonce': AppColors.navy,
    'comportement': AppColors.blue,
    'devoir': AppColors.purple,
    'absence': AppColors.orange,
  };

  @override
  Widget build(BuildContext context) {
    final enfant = context.watch<ChildProvider>().selectionne;
    if (enfant != null && enfant.id != _dernierEnfantId && !_charge) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Fil d\'actualité')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const ChildSelector(),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _charger,
              child: _charge
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? EmptyState(
                          message: 'Rien à signaler',
                          sousTitre: 'Les annonces, le comportement, les devoirs et les absences apparaîtront ici.',
                          icone: Icons.dynamic_feed_outlined,
                          onAction: _charger,
                          libelleAction: 'Actualiser',
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _items.length,
                          itemBuilder: (_, i) => AnimatedEntry(index: i, child: _carte(_items[i])),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carte(FilItem item) {
    final couleur = _couleurs[item.type] ?? AppColors.muted;
    final icone = _icones[item.type] ?? Icons.circle_outlined;

    DateTime? date;
    try { if (item.horodatage != null) date = DateTime.parse(item.horodatage!); } catch (_) {}

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icone, color: couleur, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.titre, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy)),
                  if (item.corps != null && item.corps!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.corps!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.body), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (item.photoUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(imageUrl: item.photoUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (item.auteur != null) ...[
                        Text(item.auteur!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                        const SizedBox(width: 6),
                        const Text('·', style: TextStyle(color: AppColors.muted)),
                        const SizedBox(width: 6),
                      ],
                      if (date != null)
                        Text(DateFormat('d MMM', 'fr_FR').format(date), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
