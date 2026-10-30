# Jonction Scolia ↔ Talenda

Décision (2026-11-06) : pour une école qui utilise aussi **Talenda** (son
logiciel de gestion : inscriptions, caisse, notes, vie scolaire), Talenda
est la **référence** pour les élèves, classes, matières, enseignants et
parents. Scolia garde la messagerie, le cahier de texte, les devoirs et
l'emploi du temps.

**Scolia ne dépend pas de Talenda** : la jonction est une option, école
par école. Une école sans Talenda gère tout dans Scolia, sans aucun
changement ; une école reliée peut se délier à tout moment ; et une panne
de Talenda n'empêche pas de se connecter à Scolia (voir plus bas).

Côté Talenda, voir `docs/JONCTION_SCOLIA.md` du dépôt Talenda.

## Relier une école

1. Dans **Talenda** : Paramètres → Applications connectées → « Connecter
   une application » → Scolia. Talenda affiche l'adresse de l'API et une
   clé `tlnd_…` (une seule fois).
2. Dans **Scolia** (`/admin`, compte de la direction) : menu **Talenda** →
   coller l'adresse et la clé → « Enregistrer et synchroniser ».

La clé est chiffrée en base (`tenant_settings.talenda_token`).

## Synchronisation

- Automatique toutes les 15 minutes (`scolia:talenda-sync`, planifié dans
  `routes/console.php` : activer le **scheduler** sur Laravel Cloud), et à
  la demande depuis la page Talenda.
- Rapprochement par uuid Talenda (`talenda_uuid` sur années, matières,
  classes, enseignants, élèves ; `talenda_account_uuid` et
  `talenda_guardian_uuid` sur les comptes).
- **Première synchronisation** : les fiches déjà saisies dans Scolia sont
  reprises, pas dupliquées — matière de même nom, classe de même nom dans
  l'année, élève de même matricule (ou mêmes nom, prénom et date de
  naissance), compte de même téléphone ou e-mail. Les conversations et
  devoirs existants restent donc attachés.
- **Disparition** dans Talenda : l'élève passe « transferred », le parent
  sans enfant inscrit est désactivé, le lien parent-enfant ou l'affectation
  enseignant retirés sont supprimés. Rien d'autre n'est supprimé.
- Le personnel non enseignant de Talenda (caisse, secrétariat…) n'est pas
  importé.
- En cas d'échec (Talenda injoignable, clé révoquée), rien n'est modifié
  et le message s'affiche sur la page Talenda.

## Connexion des parents et enseignants

- L'app accepte désormais `login` (téléphone ou e-mail) ; l'ancien champ
  `email` reste accepté. `06 333 33 33`, `063333333` et `+242063333333`
  désignent le même numéro.
- Un compte venu de Talenda **n'a pas de mot de passe Scolia** : Scolia
  vérifie l'identifiant et le mot de passe auprès de Talenda
  (`POST credentials/check`). Le parent utilise le mot de passe de l'app
  Talenda.
- **Talenda en panne** : à chaque connexion réussie, Scolia garde une
  copie hachée du mot de passe validé par Talenda. Si Talenda ne répond
  pas, Scolia compare avec cette copie : un compte déjà connecté une fois
  n'est jamais bloqué. Si Talenda refuse le mot de passe, la copie n'est
  pas utilisée.

## Lecture seule

Quand l'école est reliée :

- élèves, classes, matières et enseignants ne se créent plus dans Scolia ;
- les fiches venues de Talenda ne se modifient ni ne se suppriment
  (écrans `/admin` masqués, API `409 « Géré dans Talenda… »`) ;
- les champs propres à Scolia restent modifiables (activation de l'enfant,
  photo…) ;
- les comptes de la direction se créent toujours dans Scolia.

## Délier une école

Page Talenda de `/admin` → « Délier de Talenda ». Scolia redevient
autonome pour cette école :

- toutes les fiches sont conservées et redeviennent modifiables et
  créables dans Scolia ; la synchronisation s'arrête ;
- les comptes déjà connectés à Scolia gardent leur mot de passe (celui de
  Talenda) ;
- les comptes jamais connectés reçoivent un mot de passe provisoire, dans
  un fichier CSV téléchargé au moment de délier (affiché une seule fois),
  à transmettre aux familles et aux enseignants.

L'école peut se relier plus tard : la première synchronisation reprend les
fiches existantes.

## À faire ensuite

- Webhook Talenda → Scolia pour ne plus attendre 15 minutes.
- Identité parent multi-écoles (`parent_identities`) à partir du compte
  Talenda.
- Absences et annonces : afficher celles de Talenda plutôt que les saisir
  deux fois.
