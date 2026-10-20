import 'package:flutter/material.dart';

/// Fait entrer un élément de liste en fondu + léger glissement vers le
/// haut, avec un décalage croissant selon [index] — donne l'effet
/// "vivant" en défilement au lieu d'un affichage brut et statique.
/// Usage : itemBuilder: (_, i) => AnimatedEntry(index: i, child: MaCarte(...))
class AnimatedEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const AnimatedEntry({super.key, required this.index, required this.child});

  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _controleur;
  late final Animation<double> _fondu;
  late final Animation<Offset> _glissement;

  @override
  void initState() {
    super.initState();
    _controleur = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    final courbe = CurvedAnimation(parent: _controleur, curve: Curves.easeOutCubic);
    _fondu = Tween<double>(begin: 0, end: 1).animate(courbe);
    _glissement = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(courbe);

    final delai = Duration(milliseconds: 40 * (widget.index.clamp(0, 8)));
    Future.delayed(delai, () {
      if (mounted) _controleur.forward();
    });
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fondu,
      child: SlideTransition(position: _glissement, child: widget.child),
    );
  }
}
