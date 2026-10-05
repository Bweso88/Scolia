# Legacy code (référence)

Ce dossier contient la première itération de Scolia : un backend PHP procédural
(PDO + PostgreSQL) et une administration web statique (HTML/JS), mono-école
(pas de multi-tenant).

Suite à la décision produit du 15/09/2026, la plateforme repart sur une base
**Laravel + MySQL, multi-tenant dès la conception** (voir `docs/PRODUCT_ARCHITECTURE.md`).
Ce code n'est plus la base active : il est conservé uniquement comme référence
fonctionnelle (logique métier déjà pensée pour les devoirs, notes, frais,
remarques, liaison, événements...) pendant la réécriture.

Ne pas ajouter de nouvelles fonctionnalités ici. Le nouveau backend vit dans
`backend/` (Laravel).
