# SRE1 — Note de synthèse : exigences de sécurité et réglementation

Note de travail, session du 2026-10-08. Elle rassemble tout ce qui a été produit sur le référentiel d'exigences (`Docs/exigences/`) : ce qui est dans les demandes de fusion, ce qui n'est encore qu'une proposition, les sources réellement lues, les décisions en attente, et ce qui reste à creuser côté réglementation.

Légende de vérification utilisée partout : **lu** = texte officiel ouvert et relu ; **recoupé** = confirmé par des sources secondaires, texte officiel non relu ; **non vérifié** = connu mais pas confirmé ici.

---

## 1. État des demandes de fusion (au 2026-10-09)

| PR | Dépôt | Contenu | Base | État |
|---|---|---|---|---|
| #1 | factice | Nom de conteneur par environnement (`factice-app-<env>`), fiche KB-010 complétée | `main` | ouverte, CI à revérifier après la réécriture du commit |
| #2 | factice | CMDB vers un projet dédié | `main` | **fermée**, remplacée par #3 |
| #3 | factice | Retire `netbox/` et la doc CMDB dupliquées (garde le lien symbolique `scripts/cmdb`) | `main` | ouverte |
| #4 | factice | ACC-01 v0.2 : sources ASVS précisées, réserve corrigée | `main` | ouverte |
| #5 | factice | Domaine CRY : CRY-01 (flux en transit), CRY-02 (données au repos) | #4 | ouverte, empilée |
| #6 | factice | ACC-12 : authentification par OpenID Connect | #5 | ouverte, empilée |
| #8 | maisonnettev2 | Correspondance fichiers compose / environnements dans `CLAUDE.md` | `main` | ouverte, CI verte |

Ordre de fusion des PR de documentation : #4, puis #5, puis #6 (chaque base bascule sur `main` à la fusion de la précédente).

**Pas encore dans le dépôt** : la reformulation d'ACC-05 et la nouvelle ACC-13 (section 3.5). Elles sont décrites ici, rien n'est écrit dans `Docs/exigences/`.

---

## 2. Comment le référentiel est classé

- Une exigence = un identifiant (**code de domaine + numéro**, ex. `ACC-03`), stable et jamais réutilisé, avec priorité (DOIT, DEVRAIT, PEUT), applicabilité (COTS, SaaS, low code), preuve attendue (DOC, ATT, DEM, TST, CTR), version et statut.
- Un fichier par domaine (`NN-<domaine>.md`). Domaines prévus : ACC, SBOM, TRC, CRY, INT, EXP, REV, CTR. Les codes sont des abréviations propres au dépôt, pas ceux d'une norme.
- Règles du README à retenir : **une exigence, une idée** ; un domaine n'est créé qu'avec **au moins trois exigences** (avant, les idées vont dans « À instruire » du domaine le plus proche) ; un texte modifié implique une version changée et une ligne dans `journal.md` ; la version précédente d'une exigence « diffusée » n'est jamais réécrite.
- Côté CI : tout commit `feat` ou `fix` doit citer une exigence existante (`Exigence: ACC-04`) ou porter `Exigence: non-applicable` ; tout `fix` doit modifier `Docs/kb.md` ou porter `KB: KB-NNN` ou `KB: non-applicable`.


### Types de preuve (colonne « Preuve attendue »)

Chaque exigence indique comment l'éditeur démontre qu'il la respecte. Les cinq codes viennent du README du référentiel (conventions du dépôt, pas d'une norme).

| Code | Sens | Force | Exemple |
|---|---|---|---|
| DOC | Documentation de l’éditeur : il écrit que c’est le cas | Faible, déclarative | La notice dit « les données sont chiffrées en AES-256 » |
| ATT | Attestation ou certification de tiers (ISO 27001, SOC 2…) | Moyenne | Un rapport d’audit indépendant couvre le chiffrement |
| DEM | Démonstration sur notre environnement : l’éditeur le montre devant nous | Forte | L’éditeur fait une rotation de clé en direct ou nous laisse lire un volume sans la clé |
| TST | Test que nous exécutons nous-mêmes | Forte, et rejouable | On scanne les protocoles TLS acceptés, ou on rejoue un jeton falsifié |
| CTR | Engagement contractuel avec pénalité | Complète une autre preuve | L’éditeur s’engage par contrat à prévenir sous 24 heures en cas de fuite de clé |

Lecture des combinaisons utilisées dans cette note :
- **DOC + DEM** : l'éditeur fournit le texte (DOC), puis on le vérifie en direct (DEM). Le texte seul ne suffit pas.
- **DOC + CTR** : un engagement écrit (DOC) rendu opposable par le contrat (CTR). Un CTR seul ne prouve rien, il complète toujours une autre preuve.
- **TST** seul : c'est nous qui vérifions, sans nous fier à l'éditeur.
- **Règle du README** : une exigence DOIT dont la seule preuve est DOC est fragile (l'éditeur peut simplement l'affirmer) ; le champ « Réserve » doit alors le signaler.

---

## 3. Exigences travaillées

### 3.1 ACC-01 — correction de source (PR #4, v0.1 → v0.2)

La phrase de la réserve « l'API et la recherche sont des fuites classiques » n'était attribuée à aucune norme : c'était une remarque de l'auteur de la fiche (une session précédente). Vérification dans le texte de l'ASVS :

- L'**API** est couverte : ASVS 5.0 **8.2.2** (accès aux données limité aux consommateurs autorisés, contre l'IDOR et le BOLA), **8.3.1** (autorisation appliquée sur une couche de service de confiance), **8.4.1** (contrôles inter-locataires) ; équivalents 4.0.3 : **4.1.1** et **4.2.1**.
- La **recherche** n'est couverte par aucun contrôle : le mot « search » n'apparaît dans aucun des deux chapitres (V8 en 5.0, V4 en 4.0.3). Elle est donc reformulée comme retour d'expérience, signalé comme tel.
- « OWASP ASVS (contrôle d'accès) » ne donnait pas de version alors que le chapitre s'appelle V4 « Access Control » en 4.0.3 et V8 « Authorization » en 5.0, avec une autre numérotation.

### 3.2 CRY-01 — Chiffrement des flux en transit (PR #5, v0.1, brouillon)

**Énoncé.** La solution DOIT chiffrer tous les flux de données en transit (utilisateurs, API, administration, flux entre ses composants, flux vers des services tiers) avec des protocoles et des suites cryptographiques conformes à un référentiel reconnu, sans repli vers un mode non chiffré.

- **Pourquoi.** Empêcher l'écoute ou la modification des données et des identifiants sur le réseau. Un réseau interne n'est pas un réseau de confiance.
- **Priorité** DOIT. **Applicabilité** COTS, SaaS, low code.
- **Preuve.** TST : analyse des protocoles et des suites acceptés sur chaque point d'entrée exposé. DOC : schéma des flux internes indiquant le chiffrement de chacun.
- **Critère.** Seules les versions TLS 1.3 et TLS 1.2 sont acceptées, TLS 1.3 privilégiée. Aucune connexion en clair n'aboutit, ni par redirection ni par repli. Suites recommandées par l'ANSSI. Certificats des services exposés de confiance publique, vérifiés par les clients.
- **Réserve.** Le chiffrement des flux internes est le point le plus souvent déclaratif. NIST SP 800-52 Rev. 2 est en cours de révision (note de mai 2026).
- **Source.** ISO 27001:2022 A.8.24 ; ANSSI SDE-NT-35 v1.2 (R3, R4) ; NIST SP 800-52 Rev. 2 ; OWASP ASVS 5.0 : 12.1.1, 12.1.2, 12.2.1, 12.2.2, 12.3.1, 12.3.2, 12.3.3 ; RGPD art. 32.1.a.

### 3.3 CRY-02 — Chiffrement des données au repos (PR #5, v0.1, brouillon)

**Énoncé.** La solution DOIT chiffrer les données stockées (bases, fichiers, sauvegardes, journaux contenant des données sensibles) avec des algorithmes et des tailles de clé conformes à un référentiel reconnu, sans conserver les clés en clair avec les données chiffrées.

- **Pourquoi.** Limiter l'exposition en cas de vol d'un support, d'accès au stockage sous-jacent, de sauvegarde égarée ou d'instantané divulgué.
- **Preuve.** DEM : lecture directe du stockage ou d'une sauvegarde sans la clé, qui ne donne que des données illisibles. DOC : algorithmes, modes et tailles de clé par type de donnée.
- **Critère.** Chiffrement symétrique approuvé, de préférence authentifié (par exemple AES avec GCM), clés d'au moins 128 bits de sécurité. Sauvegardes et exports chiffrés au même niveau. Aucune clé en clair à côté des données. Niveaux de protection des données documentés, avec le chiffrement attendu par niveau.
- **Réserve (note de l'auteur, hors des contrôles cités).** Un chiffrement de disque ou de volume protège contre le vol du support, pas contre un accès par l'application ou un compte légitime : l'éditeur doit préciser la couche chiffrée.
- **Source.** ISO 27001:2022 A.8.24 ; ANSSI-PG-083 v3.00 (2026-03-20) ; OWASP ASVS 5.0 : 11.2.3, 11.3.2, 14.1.2 ; RGPD art. 32.1.a.
- Aucun document NIST n'a été retenu pour le repos : le seul repère est la SP 800-57, citée par l'ASVS 11.1.1, qui relève de la gestion des clés (à rédiger).

### 3.4 ACC-12 — Authentification par OpenID Connect (PR #6, v0.1, brouillon)

**Énoncé.** La solution DOIT authentifier ses utilisateurs par OpenID Connect auprès du fournisseur d'identité de l'organisation, avec le flux code d'autorisation protégé par PKCE et une validation complète du jeton d'identité reçu.

- **Pourquoi.** Une implémentation approximative (jeton accepté sans vérifier son émetteur ou son destinataire) permet de se faire passer pour un autre utilisateur : le protocole ne protège que s'il est appliqué entièrement.
- **Preuve.** TST : on rejoue des jetons d'identité invalides (signature falsifiée, mauvais émetteur, mauvais destinataire, expiré, `nonce` différent), tous refusés. DEM : connexion complète via notre fournisseur d'identité, flux code d'autorisation et PKCE observés.
- **Critère.** Flux code d'autorisation avec PKCE ; flux implicite et par mot de passe non utilisés. Jeton accepté seulement si signature valide avec les clés de l'émetteur, `iss` identique à l'émetteur préconfiguré, `aud` contenant l'identifiant du client, non expiré, `nonce` identique. Utilisateur identifié par émetteur + `sub`, jamais par adresse de messagerie ou nom.
- **Réserve.** Précise le volet OIDC d'ACC-05, qui admet aussi SAML : à aligner. Les contrôles ASVS 10.4 et 10.6 visent le serveur d'autorisation (notre fournisseur d'identité), pas la solution évaluée.
- **Source.** ISO 27001:2022 A.5.16, A.8.5 ; OpenID Connect Core 1.0 §3.1.3.7 ; RFC 9700 (janvier 2025) ; OWASP ASVS 5.0 : 10.1.2, 10.2.1, 10.2.2, 10.5.1 à 10.5.4.

### 3.5 Proposition (non écrite dans le dépôt) : ACC-05 resserrée et ACC-13

Cas déclencheur : un SaaS accessible à des utilisateurs **que le SI ne connaît pas** (clients, partenaires). Ils ne peuvent pas passer par notre fournisseur d'identité, la solution doit les authentifier elle-même, avec un second facteur et une réinitialisation du mot de passe sûre.

**ACC-05 reformulée (v0.2).** *La solution DOIT déléguer l'authentification des utilisateurs gérés par le SI de l'organisation à son fournisseur d'identité, via OpenID Connect (voir ACC-12) ou SAML, sans exiger de compte local pour ces utilisateurs.* Critère inchangé : désactiver un compte chez le fournisseur coupe l'accès.

**ACC-13 — Authentification propre des accédants inconnus du SI (nouvelle).**

**Énoncé.** Lorsque la solution est accessible à des utilisateurs que le SI de l'organisation ne connaît pas (clients, partenaires, intervenants externes), elle DOIT les authentifier par un mot de passe renforcé d'un second facteur, avec une réinitialisation du mot de passe qui ne contourne pas ce second facteur.

- **Pourquoi.** Le mot de passe seul expose aux rejeux d'identifiants volés. La réinitialisation est la voie de contournement classique : si elle ne repose que sur la messagerie, qui contrôle la boîte mail contourne le second facteur.
- **Priorité** DOIT. **Applicabilité** SaaS et low code ouverts à des utilisateurs externes.
- **Preuve.** DEM : création d'un compte externe, connexion avec second facteur, réinitialisation de bout en bout. TST : réinitialisation sans le second facteur (refusée), lien réutilisé ou expiré (refusé), compte existant et inexistant (réponses identiques).
- **Critère.** Connexion : mot de passe plus second facteur. Réinitialisation : lien ou code aléatoire, à usage unique et de durée courte, sans question secrète, sans révéler l'ancien mot de passe, sans désactiver le second facteur. Envoi sur un canal préalablement validé, avec délai d'attente après toute modification du canal, et sans confirmer l'existence du compte (CNIL 2022-100, points 55 et 56). Perte du second facteur : vérification d'identité de même niveau qu'à l'inscription. Notification de l'utilisateur après une réinitialisation. Protection contre la force brute et le rejeu d'identifiants.
- **Réserve.** Choix de l'organisation, **plus strict que l'ASVS** : le contrôle 6.3.3 (niveau 1) admet « un second facteur ou une combinaison de facteurs simples ». Imposer le second facteur suit la recommandation R1 de l'ANSSI (« privilégier »). Possible scission ultérieure : connexion d'un côté, réinitialisation de l'autre (une seule idée par exigence).
- **Source.** ISO 27001:2022 A.5.16, A.8.5 ; ANSSI-PG-078 (R1, R30) ; CNIL délibération 2022-100 ; OWASP ASVS 5.0 : 6.3.1, 6.3.3, 6.3.7, 6.3.8, 6.4.1 à 6.4.4.

---

## 4. Sources et niveau de vérification

| Source | Passage utilisé | Vérification |
|---|---|---|
| OWASP ASVS 5.0 (V6, V8, V10, V11, V12, V14) | numéros cités dans les fiches ci-dessus | **lu** (fichiers officiels) |
| OWASP ASVS 4.0.3 (V4) | 4.1.1, 4.2.1 | **lu** |
| ANSSI SDE-NT-35 v1.2, 26/03/2020 (TLS) | R3 : privilégier TLS 1.3 et accepter TLS 1.2 ; R4 : ne pas utiliser SSLv2, SSLv3, TLS 1.0, TLS 1.1 ; tables de suites recommandées | **lu** |
| ANSSI-PG-083 v3.00, 20/03/2026 (mécanismes cryptographiques) | clés symétriques d'au moins 128 bits ; AES-128, -192, -256 conformes | **lu** |
| ANSSI-PG-078, 08/10/2021 (MFA et mots de passe) | R1 : privilégier le multifacteur ; R30 : prévoir un recouvrement d'accès ; éviter l'envoi du mot de passe en clair | **lu** (extraits) |
| CNIL délibération 2022-100, 21/07/2022 (mots de passe) | entropie de 80 bits sans mesure complémentaire ; renouvellement : points 55 à 57 | **lu** (extraits) |
| NIST SP 800-52 Rev. 2 (août 2019) | TLS 1.2 exigé, TLS 1.3 à prendre en charge ; révision annoncée | **recoupé** (page officielle et résumé) |
| OpenID Connect Core 1.0 §3.1.3.7 | règles de validation du jeton d'identité | **recoupé** |
| RFC 9700 (janvier 2025) | PKCE, flux implicite et par mot de passe à proscrire | **recoupé** |
| ISO/IEC 27001:2022 A.5.16, A.8.5, A.8.24 | contrôles cités | norme payante, libellé **recoupé** |
| RGPD art. 32.1.a | chiffrement parmi les mesures appropriées | **recoupé** |
| NIST SP 800-63C-4 (juillet 2025, fédération) | existe, traite d'OIDC | **non lu**, donc non citée |

---

## 5. Décisions et points ouverts

1. **Domaine CRY avec deux exigences** : le README exige au moins trois. Options : ajouter CRY-03 (gestion des clés : ASVS 11.1.1, ISO A.8.24, NIST SP 800-57), replacer CRY-01 et CRY-02 dans « À instruire » de ACC, ou assumer l'écart. **En attente.**
2. **ACC-05, ACC-12 et ACC-13** : valider la structure (ACC-05 resserrée sur les accédants connus, ACC-13 pour les inconnus), ou tout garder dans une ACC-05 plus longue. ACC-05 admet « OIDC ou SAML » alors qu'ACC-12 impose OIDC. **En attente.**
3. **PR #1 et exigence citée** : le commit porte `Exigence: non-applicable`. ACC-01 est le plus proche (séparation des environnements) mais vise les éditeurs, pas notre infrastructure. **Choix : garder `non-applicable`.**
4. **Même vérification de source pour ACC-05 et ACC-07**, qui citent « OWASP ASVS » sans numéro de contrôle. **À faire.**
5. **Avant de fusionner la PR #1** : supprimer à la main l'ancien conteneur (`docker rm -f factice-app`), sinon conflit sur le port 3000.

---

## 6. Réglementation : ce qui reste à creuser

Cadre : la SAS Logo Solution choisit des solutions d'éditeurs (SaaS, COTS, low code) et fixe des exigences à ces éditeurs. La question réglementaire est double : **ce qui s'impose à l'organisation elle-même** (pour savoir quoi exiger) et **ce qui s'impose aux éditeurs** (pour savoir quoi leur demander de prouver).

### 6.1 Déjà vu

| Texte | Ce qui est établi | Vérification |
|---|---|---|
| RGPD art. 32.1.a | le chiffrement figure parmi les mesures techniques appropriées ; la mesure doit être adaptée au risque et à l'état de l'art | recoupé |
| CNIL, délibération 2022-100 (mots de passe) | entropie d'au moins 80 bits pour un mot de passe seul ; règles de renouvellement (canal validé, pas de confirmation de l'existence du compte, pas de questions sur des informations publiques) | **lu** |
| CNIL, délibération 2025-019 du 20/03/2025 (authentification multifacteur) | existe, publiée sur le site de la CNIL le 1er avril 2025 | existence confirmée, **contenu non lu** |

### 6.2 À creuser, par ordre d'impact sur les exigences

| # | Sujet | Pourquoi c'est pertinent | État de ce qu'on sait | À faire |
|---|---|---|---|---|
| 1 | **CNIL 2025-019, authentification multifacteur** | Elle dit dans quels cas l'absence de MFA sera considérée comme un manquement à l'art. 32 du RGPD. Direct pour ACC-13 et ACC-05. | Existence confirmée. Des sources secondaires parlent de traitements à grande échelle et de contrôles à partir de 2026 : **non vérifié** | Lire la délibération en entier : seuils, cas visés, mesures acceptées en remplacement. Ajuster la priorité d'ACC-13 en conséquence |
| 2 | **NIS 2 (directive UE 2022/2555)** | L'art. 21 impose des mesures de cryptographie (21.2.h), de contrôle d'accès (21.2.i), d'authentification multifacteur (21.2.j) et de sécurité de la chaîne d'approvisionnement (21.2.d). Les éditeurs de tes solutions peuvent être concernés. | Contenu de l'art. 21 recoupé. Transposition française : au moment de la recherche, la loi n'était pas adoptée et le projet « Résilience » aurait été retiré de l'ordre du jour de l'Assemblée le 6 octobre 2026 (une seule source, à confirmer) | 1) Déterminer si la SAS Logo Solution est une entité essentielle ou importante (secteur, taille), ou le sous-traitant d'une telle entité. 2) Vérifier l'état de la loi de transposition. 3) Lire l'art. 21 dans le texte |
| 3 | **Règlement (UE) 2024/2847, Cyber Resilience Act** | Il impose un SBOM lisible par machine (annexe I, partie II) et la déclaration des vulnérabilités. Relie le domaine **SBOM** du référentiel à une obligation légale. | Dates recoupées : notification des vulnérabilités activement exploitées à partir du **11 septembre 2026** ; application générale, SBOM compris, à partir du **11 décembre 2027** | Lire le texte : savoir si un SaaS est dans le champ (le règlement vise les « produits comportant des éléments numériques »), qui est « fabricant », et ce qu'il faut exiger d'un éditeur avant 2027 |
| 4 | **RGPD art. 28 (sous-traitant) et art. 25** | Un éditeur SaaS qui traite des données personnelles est un sous-traitant : contrat obligatoire, garanties de sécurité, audits, sous-traitants ultérieurs. Les exigences CRY et ACC doivent s'y retrouver. | Non examiné | Lister les clauses obligatoires de l'art. 28.3 et les relier aux exigences (preuve CTR) |
| 5 | **Transferts hors UE (RGPD chap. V)** | Un SaaS américain suppose un cadre de transfert. | Le cadre UE – États-Unis (Data Privacy Framework) est en vigueur ; le recours Latombe a été rejeté en première instance le 3 septembre 2025 et un **pourvoi est pendant** (C-703/25 P) — recoupé | Décider d'une exigence sur la localisation des données et les garanties de transfert ; surveiller l'arrêt |
| 6 | **RGPD art. 33 et 34 (violations de données)** | Délais de notification : l'éditeur doit prévenir le responsable de traitement assez tôt pour tenir le délai de 72 heures. | Non examiné | Exigence de délai de notification par l'éditeur (preuve CTR) |
| 7 | **Textes conditionnels** : DORA (clients du secteur financier), RGS et qualification SecNumCloud (secteur public), HDS (données de santé) | Ne s'appliquent que si tes clients ou tes données relèvent de ces cas | Non examiné | Trancher d'abord si l'un de ces cas existe, sinon les écarter explicitement dans le contexte du référentiel |
| 8 | **Régime français de la cryptologie** | Un éditeur qui fournit des moyens de cryptologie peut avoir des formalités | Non examiné | À vérifier ; probablement peu structurant pour tes exigences |

### 6.3 Questions préalables qui conditionnent tout

1. Quelles **données personnelles** traitent les solutions visées, et pour quels clients ? (RGPD, CNIL)
2. La **SAS Logo Solution est-elle dans le champ de NIS 2** (directement ou comme sous-traitante) ?
3. Les solutions visées sont-elles des **SaaS** (hébergement par l'éditeur) ou des **COTS** installés chez toi ? Le CRA et NIS 2 ne s'appliquent pas de la même façon.
4. Y a-t-il un **client public, financier ou de santé** ? (RGS, DORA, HDS)

### 6.4 Priorités suggérées

1. Lire la **CNIL 2025-019** (impact immédiat sur ACC-13).
2. Répondre aux questions préalables 1 à 4 : sans cela, NIS 2 et CRA restent des hypothèses.
3. Écrire l'exigence sur le **contrat de sous-traitance** (art. 28) et les **transferts**, qui conditionnent le choix d'un éditeur.
4. Ajouter le **domaine CRY** à trois exigences (gestion des clés) et relire **ACC-05 et ACC-07**.

---

## 7. Domaine CRY et sources ANSSI : le détail

Cette section rassemble tout ce qui touche au domaine **CRY** (chiffrement) et aux guides de l'**ANSSI** lus pendant la session. Les trois guides ont été téléchargés et relus dans le texte officiel ; ce qui n'a pas été lu est signalé.

### 7.1 Où en est le domaine CRY

- Fichier : `Docs/exigences/40-chiffrement-secrets.md` (PR #5, empilée sur #4). Deux fiches en v0.1 brouillon : **CRY-01** (flux en transit) et **CRY-02** (données au repos).
- Écart de forme : le README veut au moins trois exigences pour créer un domaine. Suite naturelle : **CRY-03 gestion des clés** (ASVS 11.1.1 qui renvoie à NIST SP 800-57, ISO 27001 A.8.24) et peut-être **CRY-04 sécurité à long terme** (voir 7.5).
- Aucun guide ANSSI dédié au chiffrement des données au repos n'a été trouvé : pour CRY-02, les repères ANSSI sont ceux du guide des mécanismes cryptographiques (7.3).

### 7.2 ANSSI, recommandations de sécurité relatives à TLS (SDE-NT-35, v1.2 du 26/03/2020, 72 pages)

Le guide compte 39 recommandations. Celles qui comptent pour CRY-01 :

| Thème | Recommandation |
|---|---|
| Versions | **R3** privilégier TLS 1.3 et accepter TLS 1.2 ; **R4** ne pas utiliser SSLv2, SSLv3, TLS 1.0 et TLS 1.1 ; R2 utiliser des composants logiciels à jour ; R1 restreindre la compatibilité en fonction du profil des clients |
| Échange de clé | R5 authentifier le serveur à l'échange de clé ; **R6 assurer toujours la confidentialité persistante (PFS)** ; R7 échanger les clés avec ECDHE ; R8 authentifier le serveur par certificat |
| Chiffrement | R9 privilégier AES ou ChaCha20 ; **R10 mode de chiffrement intègre** ; R11 SHA-2 ; R12 plusieurs suites ; R13 ordre de suites du serveur |
| Divers | R19 ne pas utiliser la compression TLS ; R20 limiter la durée de vie des tickets ; R22 renégociation sécurisée ; **R23 ne pas transmettre de données 0-RTT** |
| Certificats | R24 signé avec SHA-2 ; **R25 validité de 3 ans ou moins** ; **R26 clés de taille suffisante** ; R33 sources de révocation ; **R35 préférer l'agrafage OCSP** ; R37 réagir en hard-fail ; R38 et R39 certificats enregistrés par Certificate Transparency |

**Suites recommandées (tables 2.1 à 2.3)**
- TLS 1.3 : `TLS_AES_256_GCM_SHA384`, `TLS_AES_128_GCM_SHA256`, `TLS_AES_128_CCM_SHA256`, `TLS_CHACHA20_POLY1305_SHA256`.
- TLS 1.2 avec certificat ECDSA : `TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384`, `..._AES_128_GCM_SHA256`, `..._AES_256_CCM`, `..._AES_128_CCM`, `..._CHACHA20_POLY1305_SHA256`.
- TLS 1.2 avec certificat RSA : `TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384`, `..._AES_128_GCM_SHA256`, `..._CHACHA20_POLY1305_SHA256`.
- Le guide ajoute que si les deux extrémités sont maîtrisées, une seule suite des tables suffit (par exemple `TLS_AES_256_GCM_SHA384` avec la courbe secp256r1), à condition de pouvoir en activer une autre par configuration si un problème apparaît. L'annexe A décrit des suites de sécurité moindre, à n'envisager que pour des besoins forts de compatibilité.

**R26, tailles de clés des certificats (protection jusqu'en 2030)** : RSA d'au moins 2048 bits, ECDSA d'au moins 256 bits ; courbes retenues secp256r1, secp384r1, secp521r1, brainpoolP256r1, brainpoolP384r1, brainpoolP512r1 ; exposant public RSA supérieur ou égal à 2^16 + 1.

### 7.3 ANSSI-PG-083 v3.00 du 20/03/2026 : règles et recommandations sur les mécanismes cryptographiques

Ce guide porte le même titre que la v2.04, que beaucoup de documents citent encore, et la suit (je n'ai pas lu de mention explicite de remplacement). Règles et recommandations lues :

| Référence | Contenu |
|---|---|
| RègleTailleCléSym | taille minimale des clés symétriques : **128 bits** |
| RecoPQTailleCléSym | si une sécurité post-quantique est visée : clés symétriques d'**au moins 192 bits** |
| RègleTailleBlocSym | primitive de chiffrement par bloc sur des blocs d'**au moins 128 bits** |
| RecoModeChiff | mode non déterministe ; avec preuve de sécurité ; **ne pas employer isolément un mode sans intégrité** (le mode CBC est cité en exemple) |
| RègleHachage | empreintes d'**au moins 256 bits** |
| RègleFactorisation (RSA) | module d'au moins **2048 bits** pour un usage ne dépassant pas fin 2030, **3072 bits** à partir de 2031 ; RecoFactorisation : recommander 3072 bits même pour un usage jusqu'en 2030 |
| RègleCourbeElliptiqueGFp | sous-groupes dont l'ordre est multiple d'un nombre premier d'au moins 250 bits |
| RecoSécuLongTerme | **pour un usage au-delà du 1er janvier 2030**, ou en cas de risque d'attaque rétroactive, viser une sécurité **post-quantique** |
| RecoMécanismesÉprouvés | employer des mécanismes éprouvés et reconnus par la communauté académique |

### 7.4 ANSSI-PG-078 du 08/10/2021 : authentification multifacteur et mots de passe

Le guide compte 42 recommandations. Celles qui comptent pour ACC-13 :

| Recommandation | Contenu |
|---|---|
| R1, R2 | privilégier l'authentification multifacteur ; privilégier des moyens d'authentification forts |
| R6 | remettre les facteurs d'authentification par des canaux sécurisés |
| **R8** | **ne pas utiliser le SMS comme moyen de réception d'un facteur d'authentification** |
| R10 | limiter dans le temps le nombre de tentatives d'authentification |
| R14 | ne pas donner d'information sur l'échec de l'authentification |
| R18, R19 | processus de révocation des facteurs et délais adaptés |
| R20 à R23 | politique de mots de passe : longueur minimale, pas de longueur maximale, règles de complexité |
| R26 | révoquer immédiatement les mots de passe en cas de compromission suspectée ou avérée |
| **R30** | proposer une méthode de recouvrement d'accès adaptée au contexte (la transmission du mot de passe originel en clair est à éviter) |
| R40, R41 | ne pas utiliser un facteur inhérent (biométrie) comme unique facteur ; l'associer à un facteur fort |

Le guide est complété par la CNIL (délibération 2022-100) : elle renvoie explicitement à ce guide pour l'authentification multifacteur.

### 7.5 Ce que les guides ANSSI permettraient d'ajouter aux exigences (non appliqué)

Ces pistes ne sont dans aucune fiche : elles sont à arbitrer, en gardant la règle « dire ce qu'on veut, pas comment ».

| Exigence | Piste | Source |
|---|---|---|
| CRY-01 | Exiger la confidentialité persistante (PFS) et l'absence de données 0-RTT | ANSSI TLS R6, R7, R23 ; ASVS 12.1.2 (PFS au niveau 3) |
| CRY-01 | Durée de vie des certificats de 3 ans ou moins, révocation (agrafage OCSP) | ANSSI TLS R25, R35 ; ASVS 12.1.4 (niveau 3) |
| CRY-02 | Empreintes d'au moins 256 bits ; clés RSA d'au moins 3072 bits | ANSSI-PG-083 RègleHachage, RecoFactorisation ; ASVS 11.2.3 |
| CRY-04 (nouvelle) | **Horizon 2030 et post-quantique** : plan de migration cryptographique, clés symétriques d'au moins 192 bits si la protection doit durer | ANSSI-PG-083 RecoSécuLongTerme, RecoPQTailleCléSym ; ASVS 11.1.4 (inventaire et plan de migration, niveau 3) |
| ACC-13 | Ne pas utiliser le SMS comme second facteur ; limiter les tentatives ; ne rien révéler sur l'échec ; révoquer sans délai en cas de compromission | ANSSI-PG-078 R8, R10, R14, R26 ; CNIL 2022-100 |

### 7.6 Limites et vérifications restantes

- Le guide TLS date de **mars 2020** : je n'ai pas vérifié s'il existe une version plus récente. Les suites listées restent cohérentes avec le guide de 2026 sur les tailles de clés et de blocs, mais cette cohérence n'a pas été contrôlée ligne à ligne.
- Le guide ANSSI-PG-078 (2021) est antérieur à la recommandation CNIL sur le MFA de mars 2025, que je n'ai pas lue.
- Pas de guide ANSSI trouvé pour le chiffrement des données stockées (volumes, bases, sauvegardes) ni pour la gestion des clés : à chercher avant de rédiger CRY-03.
- Les textes ANSSI et CNIL sont lus en extraits ciblés (recherche des règles), pas en intégralité.

---

## 8. Ce que cette note ne couvre pas

- Aucun avis juridique : ce sont des repères de lecture. Les textes de loi doivent être lus dans leur version en vigueur, et la qualification de l'organisation (NIS 2, CRA) relève d'une analyse à part.
- Les résultats de recherche sur la réglementation (état de la transposition de NIS 2, dates du CRA, pourvoi sur le Data Privacy Framework) proviennent de sources secondaires datées de 2026 : à reconfirmer sur les sites officiels (EUR-Lex, Légifrance, CNIL, ANSSI) avant toute décision.
