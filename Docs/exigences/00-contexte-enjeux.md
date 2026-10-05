# Contexte et enjeux

> Brouillon à compléter. Les passages marqués **[à confirmer]** sont des hypothèses de travail.

## Contexte

La chaîne de livraison documentée dans `1-fondations/` relie plusieurs outils : référentiel d'exigences, ITSM, GitLab, registry, CMDB, documentation, base de connaissances. Plusieurs de ces outils sont des solutions d'éditeurs (COTS, SaaS, low code), sur lesquelles on n'a pas la main sur le code. Ce que l'on contrôle, c'est ce que l'on **exige** à l'achat et ce que l'on **vérifie** à la livraison.

## Enjeux

| Enjeu | Ce qu'on cherche à éviter |
|---|---|
| **Cloisonnement** | Un acteur voit ou modifie ce qui ne le concerne pas (autre équipe, autre environnement, autre client de l'éditeur) |
| **Maîtrise des droits** | Des droits excessifs, jamais revus, ou un seul compte capable de tout faire |
| **Traçabilité** | Impossible de dire qui a fait quoi, quand, avec quel droit |
| **Transparence de la chaîne** | Composants inconnus, failles non détectées (voir SBOM, décision 3 de `flux-outils.md`) |
| **Automatisation** | Un outil sans API ni intégration oblige à des gestes manuels, sources d'erreurs |
| **Dépendance** | Impossible de sortir d'un outil en récupérant ses données |

## Périmètre

- **Concerné** : les solutions achetées ou souscrites, intégrées à la chaîne de livraison **[à confirmer : liste des outils visés]**.
- **Types de solution** : COTS, SaaS, low code (voir la légende de `sre.md`).
- **Hors périmètre** : le code développé en interne, couvert par `4-securite/` et `2-pipeline-livraison/`.

## Acteurs

| Acteur | Rôle vis-à-vis du référentiel |
|---|---|
| Rédacteur du référentiel | Propose, rédige, tient le journal |
| Validateur | Approuve les exigences avant diffusion **[à confirmer : qui]** |
| Architecte / sécurité | Relit les exigences techniques et de sécurité |
| Achats / juridique | Intègre les exigences dans les consultations et les contrats **[à confirmer]** |
| Éditeur | Répond, fournit les preuves |

## Hypothèses de travail

1. Les exigences servent de base à des consultations d'éditeurs (RFI, RFP, RFQ).
2. Une exigence sans preuve attendue n'est pas retenue.
3. Les exigences sont rédigées une fois et réutilisées d'une consultation à l'autre.
4. L'environnement cible n'est pas figé : les exigences restent indépendantes du produit.

## Questions ouvertes

- Qui valide les exigences avant diffusion ?
- Quelle liste d'outils vise-t-on en premier ?
- Les exigences sont-elles reprises telles quelles dans les contrats, ou servent-elles seulement à noter les offres ?
- Quel niveau d'assurance cherche-t-on : déclaratif, ou preuves vérifiées ?
