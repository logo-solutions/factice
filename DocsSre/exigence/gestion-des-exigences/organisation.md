# Organisation : qui vit où, et ce qui est auditable

Règle de répartition entre le **dépôt GitLab** (avec pipeline) et le **wiki**.

## La règle

> **Ce que l'on cite dans un contrat ou que l'on audite vit dans le dépôt. Ce qui se discute et se raconte vit dans le wiki.**

| Objet | Où | Pourquoi |
|---|---|---|
| Exigences (`ACC-01`…), versions, journal | **Dépôt** : demandes de fusion, étiquettes | Citées dans les contrats : relues, versionnées, contrôlées par le pipeline |
| Réponses des éditeurs, conformité par exigence | **Dépôt** : un fichier structuré par éditeur et par consultation | Lisibles par le pipeline, qui calcule la matrice de conformité |
| Consultations RFI / RFP / RFQ : cadrage, questionnaire, planning, comptes rendus, décision | **Wiki** | Texte narratif, écrit à plusieurs, qui change vite |
| Références externes (normes, signets) | **Wiki** | Liens vivants, hors périmètre d'audit |

Les modèles sont dans [modeles/](modeles/) : gabarit d'exigence (dépôt), page de consultation (wiki), fichier de réponse d'éditeur (dépôt).

## Lien entre les deux

- Une page de consultation du wiki cite les exigences sous la forme `ACC-01 v1.0`, avec un lien vers l'**étiquette** du dépôt qui fige leur texte. C'est ce qui permet de savoir à quel énoncé l'éditeur a répondu.
- La synthèse des réponses dans le wiki renvoie vers la **matrice** produite par le pipeline. Le wiki ne contient pas de chiffres saisis à la main : ils viennent du dépôt.
- À chaque envoi à un éditeur, la page de consultation note la **date** et le **numéro de commit du wiki** : le wiki n'a pas d'étiquette, c'est la seule façon de retrouver ce qui a été envoyé.

## Ce que le pipeline contrôle

| Contrôle | Pourquoi |
|---|---|
| Identifiants d'exigences uniques, jamais réutilisés | Traçabilité stable |
| Texte modifié ⇒ version changée ⇒ ligne dans le journal | Aucune modification silencieuse |
| Table de synthèse du domaine conforme aux fiches | Pas de dérive entre vue d'ensemble et détail |
| Exigence `diffusée` non modifiée sur place | Ce qui a été envoyé reste retrouvable |
| Exigence DOIT dont la seule preuve est déclarative : signalée | Alerte sur les preuves fragiles |
| Chaque réponse d'éditeur cite une exigence et une version existantes, avec une conformité valide | Réponses exploitables |
| Écart renseigné quand la conformité n'est pas « conforme » | Pas de réponse partielle sans explication |
| Preuve marquée « vérifiée » : vérificateur et date renseignés | La vérification est un acte tracé |
| Liens vivants (références externes) | Pas de références mortes |

Le pipeline produit une **matrice de traçabilité** (exigence, version, consultation, éditeur, conformité, preuve, vérification), conservée comme artefact du job. C'est la pièce à présenter lors d'un audit.

## Ce qui rend le dépôt auditable côté GitLab

- Branche principale protégée : tout passe par une demande de fusion.
- Approbation obligatoire d'un validateur pour le passage en `validée`.
- Journal d'audit GitLab : qui a approuvé, quand.
- Étiquette à chaque diffusion à un éditeur.

## Limites

- Le pipeline prouve la **cohérence et la traçabilité**, pas que l'éditeur dit vrai. La vérification d'une preuve (démonstration, test rejoué) reste un acte humain, que l'on consigne dans le fichier de réponse.
- Une consultation contient des prix et des réponses confidentiels : le dépôt et le wiki sont limités aux membres concernés.
- Le wiki n'a ni relecture ni contrôle : un questionnaire modifié après envoi n'est pas bloqué. D'où la date d'envoi et le commit notés dans la page.
- Aujourd'hui, factice est sur GitHub. Les contrôles sont écrits pour être lancés par n'importe quel pipeline (GitLab CI ou GitHub Actions). Le wiki GitLab n'existe que sur GitLab.
