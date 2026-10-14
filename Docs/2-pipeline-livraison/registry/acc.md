# Exigences ACC applicables au registry (lot 1)

Registre des exigences du domaine ACC (`Docs/exigences/10-controle-acces-segregation.md`) appliquées au registry Nexus Repository Pro, pilote `service.hra`.

Statut d'applicabilité : **proposé**, à valider. Les titres et priorités viennent de la table de synthèse du document ACC ; le texte complet de chaque exigence reste à relire avant recette.

| Réf. | Exigence | Priorité | Lien avec le lot 1 | Story | Applicabilité lot 1 |
|---|---|---|---|---|---|
| ACC-01 | Ségrégation logique par périmètre | DOIT | Cloisonnement d'Achera (`service.hra`) des autres applications | S2 | Oui |
| ACC-02 | Contrôle d'accès par rôles | DOIT | Rôles lecteur, éditeur, promotion, exploitation, SSI | S3 | Oui |
| ACC-03 | Moindre privilège par défaut | DOIT | Chaque rôle ne voit que son périmètre ; accès anonyme refusé | S3 | Oui |
| ACC-04 | Séparation des tâches | DOIT | Le compte qui publie en candidat n'est pas celui qui promeut en release | S3, S6 | Oui |
| ACC-05 | Authentification déléguée et MFA | DOIT | Comptes locaux au lot 1 ; annuaire d'entreprise à connecter | S3 | À arbitrer (annuaire) |
| ACC-06 | Provisionnement automatisé des accès | DEVRAIT | Gestion manuelle au lot 1 | — | Reporté |
| ACC-07 | Comptes techniques maîtrisés | DOIT | Compte de service de déploiement : lecture seule, identifiants hors dépôt | S6 | Oui |
| ACC-08 | Journal des accès et des changements de droits | DOIT | Journal d'audit de Nexus Pro conservé | S9 (à ajouter) | À confirmer |
| ACC-09 | Export des droits pour revue | DEVRAIT | Revue périodique des rôles | — | Reporté |
| ACC-10 | Accès du personnel de l'éditeur | DOIT | Sans objet : Nexus est un produit installé, pas un service éditeur | — | Non applicable |
| ACC-11 | Isolation entre clients de l'éditeur | DOIT | Sans objet : pas de clients multiples | — | Non applicable |

## Points à trancher

- **ACC-05** : faut-il connecter l'annuaire d'entreprise dès le lot 1, pour l'authentification déléguée et le MFA ?
- **ACC-08** : le journal d'audit de Nexus Pro est-il exporté et conservé, et pendant combien de temps ?
- **ACC-06 et ACC-09** : reportés, à réévaluer à la sortie du lot 1.
