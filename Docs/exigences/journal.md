# Journal du référentiel

Une ligne par changement de fond : date, identifiant, versions, ce qui change, pourquoi. Les corrections de forme n'y figurent pas.

| Date | Identifiant | Version | Changement | Pourquoi |
|---|---|---|---|---|
| 2026-10-05 | — | — | Création du dossier `exigences/` : README, contexte, gabarit | Démarrer le référentiel d'exigences éditeurs |
| 2026-10-05 | ACC-01 à ACC-11 | 0.1 | Premier jet du domaine contrôle d'accès et ségrégation logique (statut `brouillon`) | Priorité exprimée : ségrégation logique, rôles |
| 2026-10-05 | ACC-01 à ACC-11 | 0.1 | Ajout du champ Version et des règles de versionnement | Les exigences évoluent et les consultations doivent citer un état précis |
| 2026-10-05 | — | — | Ajout de `organisation.md` (règle dépôt / wiki, contrôles du pipeline) et de `modeles/` : page de consultation, réponse d'éditeur ; gabarit d'exigence déplacé dans `modeles/` | Séparer ce qui est audité (dépôt) de ce qui se discute (wiki), et préparer RFI / RFP / RFQ |
| 2026-10-08 | ACC-01 | 0.1 → 0.2 | Source précisée (OWASP ASVS 5.0 : 8.2.2, 8.3.1, 8.4.1 ; 4.0.3 : 4.1.1, 4.2.1) et réserve reformulée : l'API est couverte par l'ASVS, la recherche est une note d'expérience sans contrôle dédié | La phrase d'origine n'était attribuée à aucune norme ; mineure, ce qu'on exige ne change pas |
| 2026-10-08 | CRY-01, CRY-02 | 0.1 | Création du domaine chiffrement : flux en transit (CRY-01) et données au repos (CRY-02), statut `brouillon`, sources vérifiées listées dans le fichier | Besoin exprimé : exiger le chiffrement des flux et des données stockées ; scindé en deux car une exigence porte une seule idée |
| 2026-10-08 | ACC-12 | 0.1 | Création : authentification par OpenID Connect (code d'autorisation, PKCE, validation du jeton d'identité), statut `brouillon` | Détailler le volet OIDC d'ACC-05, qui mélange OIDC, SAML et MFA |
