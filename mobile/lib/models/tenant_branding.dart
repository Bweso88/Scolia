import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Identité visuelle de l'école, chargée au runtime depuis l'API
/// (docs/PRODUCT_ARCHITECTURE.md §5 et §16) : la plateforme Scolia reste
/// discrète derrière le logo et les couleurs de chaque établissement.
class TenantBranding {
  final int id;
  final String name;
  final String displayName;
  final String? logoUrl;
  final String? coverImageUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final String? phone;
  final String? email;
  final String? address;
  final String? messagingCutoffTime;

  const TenantBranding({
    required this.id,
    required this.name,
    required this.displayName,
    this.logoUrl,
    this.coverImageUrl,
    required this.primaryColor,
    required this.secondaryColor,
    this.phone,
    this.email,
    this.address,
    this.messagingCutoffTime,
  });

  factory TenantBranding.fromJson(Map<String, dynamic> j) => TenantBranding(
        id:            j['id'] as int,
        name:          j['name'] as String,
        displayName:   j['display_name'] as String? ?? j['name'] as String,
        logoUrl:       j['logo_url'] as String?,
        coverImageUrl: j['cover_image_url'] as String?,
        primaryColor:   _couleur(j['primary_color'] as String?)   ?? AppColors.navy,
        secondaryColor: _couleur(j['secondary_color'] as String?) ?? AppColors.amber,
        phone:   j['phone'] as String?,
        email:   j['email'] as String?,
        address: j['address'] as String?,
        messagingCutoffTime: j['messaging_cutoff_time'] as String?,
      );

  /// L'heure limite est au format "HH:MM:SS" (colonne SQL `time`) ;
  /// on ne compare que les 5 premiers caractères pour matcher
  /// DateFormat('HH:mm').format(now()).
  bool get messagerieFermee {
    if (messagingCutoffTime == null) return false;
    final maintenant = TimeOfDay.now();
    final heureLimite = messagingCutoffTime!.split(':');
    final limite = TimeOfDay(hour: int.parse(heureLimite[0]), minute: int.parse(heureLimite[1]));
    return maintenant.hour > limite.hour || (maintenant.hour == limite.hour && maintenant.minute >= limite.minute);
  }

  static Color? _couleur(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final nettoye = hex.replaceFirst('#', '');
    final valeur = int.tryParse(nettoye, radix: 16);
    if (valeur == null) return null;
    return Color(0xFF000000 | valeur);
  }
}
