import 'dart:math';
import 'package:flutter/material.dart';

/// Petite animation ludique jouée juste après la connexion : des émojis
/// tombent du haut de l'écran, rebondissent une fois en bas comme un
/// ballon, puis glissent vers la gauche ou la droite en disparaissant.
/// Purement décorative (IgnorePointer) — [onDone] est appelé une fois
/// que tous les éléments ont fini leur course.
class FallingEmojiOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const FallingEmojiOverlay({super.key, required this.onDone});

  @override
  State<FallingEmojiOverlay> createState() => _FallingEmojiOverlayState();
}

class _ElementChute {
  final String emoji;
  final double colonneFrac;
  final int delaiMs;
  final bool sortAGauche;
  final double taille;

  const _ElementChute({
    required this.emoji,
    required this.colonneFrac,
    required this.delaiMs,
    required this.sortAGauche,
    required this.taille,
  });
}

class _FallingEmojiOverlayState extends State<FallingEmojiOverlay> with TickerProviderStateMixin {
  static const _dureeParElement = Duration(milliseconds: 1700);

  final _elements = const [
    _ElementChute(emoji: '👧🏿', colonneFrac: 0.22, delaiMs: 0, sortAGauche: true, taille: 46),
    _ElementChute(emoji: '👦🏿', colonneFrac: 0.76, delaiMs: 180, sortAGauche: false, taille: 46),
    _ElementChute(emoji: '🏀', colonneFrac: 0.42, delaiMs: 360, sortAGauche: true, taille: 38),
    _ElementChute(emoji: '📐', colonneFrac: 0.60, delaiMs: 520, sortAGauche: false, taille: 34),
  ];

  late final List<AnimationController> _controleurs;

  @override
  void initState() {
    super.initState();
    _controleurs = _elements.map((_) => AnimationController(vsync: this, duration: _dureeParElement)).toList();

    for (var i = 0; i < _elements.length; i++) {
      Future.delayed(Duration(milliseconds: _elements[i].delaiMs), () {
        if (mounted) _controleurs[i].forward();
      });
    }

    final dureeTotale = _dureeParElement.inMilliseconds +
        _elements.map((e) => e.delaiMs).reduce((a, b) => a > b ? a : b);
    Future.delayed(Duration(milliseconds: dureeTotale + 150), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    for (final c in _controleurs) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taille = MediaQuery.of(context).size;
    final hAtterrissage = taille.height * 0.62;

    return IgnorePointer(
      child: Stack(
        children: List.generate(_elements.length, (i) {
          final e = _elements[i];
          return AnimatedBuilder(
            animation: _controleurs[i],
            builder: (context, _) {
              final t = _controleurs[i].value;
              double y;
              double xDecalage = 0;
              double opacite = 1;

              if (t < 0.55) {
                final p = Curves.easeIn.transform(t / 0.55);
                y = -60 + p * (hAtterrissage + 60);
              } else if (t < 0.70) {
                final p = Curves.easeOut.transform((t - 0.55) / 0.15);
                y = hAtterrissage - sin(p * pi) * 34;
              } else if (t < 0.82) {
                final p = Curves.easeIn.transform((t - 0.70) / 0.12);
                y = hAtterrissage - (1 - p) * 10;
              } else {
                final p = Curves.easeIn.transform((t - 0.82) / 0.18);
                xDecalage = (e.sortAGauche ? -1 : 1) * p * (taille.width * 0.7);
                y = hAtterrissage - 10 * (1 - p);
                opacite = 1 - p;
              }

              return Positioned(
                left: taille.width * e.colonneFrac - e.taille / 2 + xDecalage,
                top: y,
                child: Opacity(
                  opacity: opacite.clamp(0, 1),
                  child: Text(e.emoji, style: TextStyle(fontSize: e.taille)),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
