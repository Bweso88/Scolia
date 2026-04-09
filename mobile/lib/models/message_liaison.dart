class MessageLiaison {
  final int id;
  final String? titre;
  final String contenu;
  final String categorie;
  final bool necessite_ack;
  final String? auteurPrenom;
  final String? auteurNom;
  final String? classeNom;
  final String createdAt;
  final bool? accuse_reception;

  const MessageLiaison({
    required this.id,
    this.titre,
    required this.contenu,
    required this.categorie,
    required this.necessite_ack,
    this.auteurPrenom,
    this.auteurNom,
    this.classeNom,
    required this.createdAt,
    this.accuse_reception,
  });

  factory MessageLiaison.fromJson(Map<String, dynamic> j) => MessageLiaison(
        id:               j['id'] as int,
        titre:            j['titre'] as String?,
        contenu:          j['contenu'] as String,
        categorie:        j['categorie'] as String? ?? 'info',
        necessite_ack:    j['necessite_ack'] == true || j['necessite_ack'] == 1,
        auteurPrenom:     j['auteur_prenom'] as String?,
        auteurNom:        j['auteur_nom'] as String?,
        classeNom:        j['classe_nom'] as String?,
        createdAt:        j['created_at'] as String,
        accuse_reception: j['accuse_reception'] as bool?,
      );
}
