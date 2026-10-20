# CRY — Chiffrement et gestion des secrets

Premier jet à challenger. Toutes les exigences sont en version `0.1`, statut `brouillon`. Règles de versionnement : voir le [README](README.md#versionnement).

## Enjeu du domaine

Une solution doit **protéger la confidentialité et l'intégrité des données** quand elles circulent sur un réseau et quand elles sont stockées, avec des mécanismes cryptographiques reconnus et à jour. Sans cela, une écoute du réseau, le vol d'un support, une sauvegarde égarée ou un instantané exposé suffisent à divulguer les données.

Ce domaine commence par le chiffrement des flux (CRY-01) et des données stockées (CRY-02). La gestion des clés et des secrets (cycle de vie, rotation, inventaire) reste à rédiger.

## Vue d'ensemble

| ID | Titre | Version | Priorité | Preuve principale |
|---|---|---|---|---|
| CRY-01 | Chiffrement des flux en transit | 0.1 | DOIT | TST |
| CRY-02 | Chiffrement des données au repos | 0.1 | DOIT | DEM |

## Exigences

### CRY-01 — Chiffrement des flux en transit

**Énoncé.** La solution DOIT chiffrer tous les flux de données en transit (utilisateurs, API, administration, flux entre ses composants, flux vers des services tiers) avec des protocoles et des suites cryptographiques conformes à un référentiel reconnu, sans repli vers un mode non chiffré.

**Pourquoi.** Empêcher l'écoute ou la modification des données et des identifiants sur le réseau. Un réseau interne n'est pas un réseau de confiance : un flux entre deux composants est exposé comme un flux vers l'extérieur.

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | COTS, SaaS, low code |
| Preuve attendue | TST : analyse des protocoles et des suites acceptés sur chaque point d'entrée exposé (interface, API, administration). DOC : schéma des flux internes indiquant le chiffrement de chacun |
| Critère d'acceptation | Seules les versions TLS 1.3 et TLS 1.2 sont acceptées, TLS 1.3 étant privilégiée. Aucune connexion en clair n'aboutit, ni par redirection ni par repli. Les suites sont celles recommandées par l'ANSSI. Les certificats des services exposés sont de confiance publique et les clients vérifient les certificats reçus |
| Réserve | Le chiffrement des flux **internes** est le point le plus souvent déclaratif : la preuve DOC est faible, demander un test ou une démonstration quand c'est possible. Les référentiels de version TLS évoluent (NIST SP 800-52 Rev. 2 est en cours de révision en 2026) |
| Source | ISO 27001:2022 A.8.24 ; ANSSI SDE-NT-35 v1.2 (R3, R4) ; NIST SP 800-52 Rev. 2 ; OWASP ASVS 5.0 : 12.1.1, 12.1.2, 12.2.1, 12.2.2, 12.3.1, 12.3.2, 12.3.3 ; RGPD art. 32.1.a |
| Version | 0.1 |
| Statut | brouillon |

### CRY-02 — Chiffrement des données au repos

**Énoncé.** La solution DOIT chiffrer les données stockées (bases, fichiers, sauvegardes, journaux contenant des données sensibles) avec des algorithmes et des tailles de clé conformes à un référentiel reconnu, sans conserver les clés en clair avec les données chiffrées.

**Pourquoi.** Limiter l'exposition en cas de vol d'un support, d'accès au stockage sous-jacent, de sauvegarde égarée ou d'instantané divulgué.

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | COTS, SaaS, low code |
| Preuve attendue | DEM : lecture directe du stockage ou d'une sauvegarde sans la clé, qui ne donne que des données illisibles. DOC : algorithmes, modes et tailles de clé par type de donnée |
| Critère d'acceptation | Chiffrement symétrique approuvé, de préférence authentifié (par exemple AES avec GCM), avec des clés d'au moins 128 bits de sécurité. Les sauvegardes et les exports sont chiffrés au même niveau. Aucune clé n'est stockée en clair à côté des données qu'elle protège. La documentation des niveaux de protection des données précise le chiffrement attendu pour chaque niveau |
| Réserve | Note de l'auteur, hors des contrôles cités : un chiffrement de disque ou de volume protège contre le vol du support, mais pas contre un accès par l'application ou par un compte légitime. L'éditeur doit préciser la couche chiffrée (volume, base de données, champ) |
| Source | ISO 27001:2022 A.8.24 ; ANSSI-PG-083 v3.00 (2026-03-20) ; OWASP ASVS 5.0 : 11.2.3, 11.3.2, 14.1.2 ; RGPD art. 32.1.a |
| Version | 0.1 |
| Statut | brouillon |

## Sources consultées

Les numéros de contrôle sont à confirmer sur la version en vigueur avant diffusion (voir le [README](README.md)).

| Référentiel | Version lue | Ce qui est repris | Vérification |
|---|---|---|---|
| OWASP ASVS | 5.0, chapitres V11, V12, V14 | 12.1.1 (TLS 1.2 et 1.3 seulement), 12.2.1 (TLS partout, sans repli), 12.3.1 (tous les flux entrants et sortants chiffrés), 12.3.3 (flux internes chiffrés), 11.2.3 (128 bits de sécurité au minimum), 11.3.2 (chiffrements approuvés, par exemple AES-GCM), 14.1.2 (exigences de protection documentées par niveau, dont le chiffrement au niveau base de données) | Texte officiel lu |
| ANSSI, recommandations de sécurité relatives à TLS (SDE-NT-35) | 1.2, 26/03/2020 | R3 : privilégier TLS 1.3 et accepter TLS 1.2. R4 : ne pas utiliser SSLv2, SSLv3, TLS 1.0 et TLS 1.1 | Texte officiel lu |
| ANSSI, règles et recommandations concernant le choix et le dimensionnement des mécanismes cryptographiques (ANSSI-PG-083) | 3.00, 20/03/2026 | Taille minimale des clés symétriques : 128 bits ; AES-128, AES-192 et AES-256 conformes | Texte officiel lu |
| NIST SP 800-52 | Rev. 2, août 2019 (révision annoncée le 05/2026) | TLS 1.2 exigé, TLS 1.3 à prendre en charge | Page officielle et résumé lus, texte intégral non relu |
| ISO/IEC 27001:2022 | Annexe A, A.8.24 (utilisation de la cryptographie) | Règles d'utilisation de la cryptographie, gestion des clés comprise | Norme payante : libellé vérifié par des sources secondaires |
| RGPD | Article 32, paragraphe 1, point a | Chiffrement des données à caractère personnel parmi les mesures appropriées | Texte juridique connu, recoupé par des sources secondaires |

Aucun document du NIST n'a été retenu pour le chiffrement au repos : le seul repère trouvé pour la gestion des clés est la SP 800-57, citée par l'ASVS 11.1.1, qui relève de l'exigence de gestion des clés à rédiger.
