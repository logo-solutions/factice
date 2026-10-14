# Gabarit d'exigence

Copier le bloc ci-dessous dans le fichier du domaine, remplir les champs, supprimer les lignes d'aide.

```markdown
### XXX-00 — Titre court

**Énoncé.** Le fournisseur DOIT/DEVRAIT/PEUT … (une phrase, une exigence, vérifiable).

**Pourquoi.** Risque ou enjeu couvert, en une ou deux phrases.

| | |
|---|---|
| Priorité | DOIT / DEVRAIT / PEUT |
| Applicabilité | COTS, SaaS, low code (garder ce qui s'applique) |
| Preuve attendue | DOC / ATT / DEM / TST / CTR (et précisément laquelle) |
| Critère d'acceptation | Ce qu'on observe quand c'est conforme |
| Réserve | Pourquoi la preuve est faible, s'il y a lieu |
| Source | Norme, guide ou décision (contrôle précis) |
| Version | 0.1 (puis 1.0 à la validation ; règles dans le README) |
| Statut | brouillon / à valider / validée / diffusée / obsolète |
| Dernière mise à jour | AAAA-MM-JJ |
```

## Faire évoluer une exigence

1. Modifier le bloc et incrémenter la version : mineure si le sens ne change pas, majeure sinon (voir le README).
2. Mettre à jour la colonne Version de la table de synthèse du domaine.
3. Ajouter une ligne dans [journal.md](../journal.md).
4. Si la version précédente était `diffusée`, ne pas écraser son texte sans passer à la version suivante.

## Règles de rédaction

1. **Une exigence, une idée.** Si l'énoncé contient « et », envisager de le scinder.
2. **Vérifiable.** Si on ne peut pas décrire la preuve, l'énoncé est trop vague. Reformuler.
3. **Dire ce qu'on veut, pas comment.** « Les droits sont limités à un périmètre » vaut mieux que « utiliser telle technologie ».
4. **Le pourquoi est obligatoire.** Il permet d'arbitrer quand l'éditeur propose une alternative.
5. **Pas de nom de produit ni d'éditeur** dans l'énoncé.
