# Modèle : page de consultation (wiki)

À copier dans le **wiki**, une page par consultation, sous `Consultations/CONS-AAAA-NN-<objet>`. Supprimer les lignes d'aide et les sections qui ne s'appliquent pas au type de consultation.

## Quel type de consultation ?

| | **RFI** | **RFP** | **RFQ** |
|---|---|---|---|
| Objet | Cartographier le marché | Comparer des solutions | Obtenir un prix ferme |
| Quand | Besoin ou solution encore flous | Besoin défini, plusieurs approches possibles | Solution et spécifications arrêtées |
| Réponse attendue | Informations, références, ordres de grandeur | Solution, méthode, prix | Offre chiffrée qui engage |
| Notation | Non | Oui, critères pondérés | Prix et conditions |
| Exigences envoyées | Un échantillon, pour tester la maturité | Toutes les `validée`, avec priorité | Celles déjà retenues |
| Suite | Rédiger un RFP ou un RFQ | Choisir, puis RFQ ou contrat | Commande ou contrat |

## Modèle de page

````markdown
# CONS-AAAA-NN — <objet de la consultation>

| | |
|---|---|
| Type | RFI / RFP / RFQ |
| Statut | cadrage / envoyée / réponses reçues / dépouillement / décidée / close |
| Responsable | |
| Validateur | |
| Date d'envoi | AAAA-MM-JJ |
| Commit du wiki à l'envoi | `abc1234` (ce qui a été envoyé) |
| Date limite de réponse | AAAA-MM-JJ |

## 1. Objectif et contexte

Pourquoi cette consultation, ce qu'elle doit permettre de décider. Renvoi vers `00-contexte-enjeux.md`.

## 2. Périmètre

Type de solution visé (COTS, SaaS, low code), intégration à la chaîne de livraison, ce qui est hors périmètre.

## 3. Exigences retenues

| ID | Version | Priorité | Preuve attendue | Texte figé |
|---|---|---|---|---|
| ACC-01 | 1.0 | DOIT | DEM | lien vers l'étiquette du dépôt |

Seules des exigences au statut `validée` ou `diffusée` figurent ici.

## 4. Éditeurs consultés

| Éditeur | Solution | Contact | Envoi | Réponse reçue |
|---|---|---|---|---|

Les réponses détaillées sont dans le dépôt : `consultations/CONS-AAAA-NN/reponses/<editeur>.yml`.

## 5. Règles de réponse

Format attendu (voir [reponse-editeur.yml](reponse-editeur.yml)), délai, canal de questions, confidentialité.

## 6. Critères de notation  (RFP, RFQ)

| Critère | Poids | Mesure |
|---|---|---|

## 7. Planning

| Étape | Date |
|---|---|
| Envoi | |
| Questions des éditeurs | |
| Réponses | |
| Dépouillement | |
| Décision | |

## 8. Résultats

Synthèse de conformité : lien vers la matrice produite par le pipeline (artefact du dernier job). Ne pas recopier les chiffres à la main.

## 9. Décision et suite

Éditeur ou solution retenue, motifs, écarts acceptés (par identifiant d'exigence), prochaines actions.

## 10. Comptes rendus

Une ligne par échange : date, participants, points clés.
````
