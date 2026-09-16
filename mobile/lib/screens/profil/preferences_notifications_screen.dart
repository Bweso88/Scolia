import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/notification_preference_service.dart';

/// Réglages des notifications par catégorie (docs/PRODUCT_ARCHITECTURE.md
/// §16) : actives par défaut, désactivables une à une.
class PreferencesNotificationsScreen extends StatefulWidget {
  const PreferencesNotificationsScreen({super.key});

  @override
  State<PreferencesNotificationsScreen> createState() => _PreferencesNotificationsScreenState();
}

class _PreferencesNotificationsScreenState extends State<PreferencesNotificationsScreen> {
  final _service = NotificationPreferenceService();
  final Map<String, bool> _valeurs = {};
  bool _charge = false;

  static const _categories = {
    'devoir':   ('Nouveaux devoirs', Icons.assignment_outlined),
    'absence':  ('Absences et retards', Icons.event_busy_outlined),
    'message':  ('Messages', Icons.forum_outlined),
    'annonce':  ('Annonces de l\'école', Icons.campaign_outlined),
  };

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      final prefs = await _service.getPreferences();
      setState(() {
        for (final cle in _categories.keys) {
          _valeurs[cle] = prefs['${cle}_push'] ?? true;
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _basculer(String categorie, bool valeur) async {
    setState(() => _valeurs[categorie] = valeur);
    try {
      await _service.definir(categorie, valeur);
    } catch (_) {
      if (mounted) setState(() => _valeurs[categorie] = !valeur);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: _categories.entries.map((entree) {
                final (libelle, icone) = entree.value;
                return SwitchListTile(
                  secondary: Icon(icone, color: AppColors.navy),
                  title: Text(libelle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  value: _valeurs[entree.key] ?? true,
                  activeColor: AppColors.navy,
                  onChanged: (v) => _basculer(entree.key, v),
                );
              }).toList(),
            ),
    );
  }
}
