# Décisions d'architecture

Chaque décision suit la même forme : la décision, ses raisons, l'alternative écartée, la conclusion.

## 1. Node.js et Express pour l'application

**Décision** : le backend est écrit en Node.js avec Express.

**Raisons**
- Node.js et npm sont un standard des chaînes CI/CD.
- Express est minimal et représentatif d'une API courante.
- Le support de Node.js dans Docker est mature.

**Alternative écartée** : Python avec FastAPI. Choix tout aussi valable, mais l'environnement d'exécution est un peu plus lourd.

**Conclusion** : Node.js, pour sa simplicité et son large support en CI/CD.

---

## 2. Reverse proxy natif, hors Docker

**Décision** : Caddy est installé par Homebrew et exécuté comme processus macOS natif, géré par un LaunchAgent.

**Raisons**
- Montrer qu'Ansible orchestre autre chose que des conteneurs.
- Illustrer la gestion d'un service Homebrew et d'un LaunchAgent de façon idempotente et déclarative.
- Refléter les déploiements réels, où tout ne tourne pas dans Docker.

**Alternative écartée** : exécuter le reverse proxy dans un conteneur. C'est plus simple (tout passerait par `deploy_stack`), mais on perdrait la démonstration de l'orchestration de services natifs.

**Conclusion** : reverse proxy natif, via Homebrew et LaunchAgent.

---

## 3. Base de données native, hors Docker

**Décision** : PostgreSQL est installé par Homebrew et géré par `brew services`.

**Raisons**
- Montrer l'orchestration multi-tiers, au-delà de Docker.
- Valider la gestion des utilisateurs et des mots de passe par le coffre Ansible.
- Refléter un déploiement où la base est un service géré à part.

**Alternative écartée** : SQLite (fichier local). Aucune dépendance externe, mais aucune orchestration de service ni gestion d'utilisateurs à démontrer.

**Conclusion** : PostgreSQL via Homebrew et `brew services`.

---

## 4. Nexus configuré par Ansible

**Décision** : `roles/nexus` déploie Nexus si besoin, puis configure l'instance par l'API REST : dépôts candidat, release et proxy, blob stores, politiques de nettoyage, rôles, comptes de service et tâches planifiées.

**Raisons**
- Une configuration faite à la main n'est ni reproductible ni auditable.
- Le principe de l'infrastructure as code est « tout est déclaratif, rien n'est manuel ».
- Le rôle est idempotent et se termine par un contrôle de conformité : un second passage ne change rien.

**Alternative écartée** : configurer Nexus manuellement avant de lancer Ansible. C'est plus rapide pour une maquette, mais Nexus n'y serait plus « un service comme les autres ».

**Conclusion** : `roles/nexus` configure l'instance. La gouvernance qu'il met en œuvre est décrite dans [nexus/](2-pipeline-livraison/registry/README.md).

---

## 5. Runner GitHub Actions auto-hébergé

**Décision** : le runner GitHub Actions est installé sur l'hôte macOS, comme LaunchAgent.

**Raisons**
- Nexus tourne sur le même hôte macOS et n'est pas exposé publiquement.
- Un runner hébergé par GitHub ne peut pas atteindre Nexus sans adresse publique ni tunnel.
- Un runner auto-hébergé correspond à un contexte réel, où les services restent internes.

**Alternative écartée** : exposer Nexus par un tunnel et utiliser un runner hébergé. C'est plus compliqué, moins représentatif, et cela dégrade la posture de sécurité puisque Nexus deviendrait public.

**Conclusion** : runner auto-hébergé sur l'hôte macOS.

---

## 6. Chaîne CI/CD en quatre étapes, avec promotion

**Décision** : le workflow `ci.yml` enchaîne `build`, `promote`, `deploy-integration` et `deploy-production`.

1. `build` : tests bloquants, génération du SBOM, publication de l'image dans `docker-candidat`.
2. `promote` : contrôles, puis republication dans `docker-release`.
3. `deploy-*` : déploiement de l'image release, référencée par son empreinte.

**Raisons**
- Un artefact n'est déployable qu'après avoir été promu : ce qui est déployé est exactement ce qui a été contrôlé.
- Les comptes sont cloisonnés : celui qui construit ne peut pas écrire en release, celui qui déploie ne fait que lire.
- Une release est immuable et n'utilise aucune étiquette `latest`.

**Alternative écartée** : un workflow simple (tests, construction, publication unique). Plus rapide à mettre en place, mais sans contrôle entre la construction et le déploiement.

**Conclusion** : build, candidat, promotion, release, déploiement par empreinte. Détails dans [nexus/README.md](2-pipeline-livraison/registry/README.md).

---

## 7. Promotion par republication

**Décision** : sur Nexus Community, la promotion est une republication contrôlée du candidat vers la release, avec copie du manifeste et du SBOM.

**Raisons**
- La Community Edition n'a pas de promotion native.
- L'image republiée garde la même empreinte : ce qui est déployé reste identique à ce qui a été contrôlé.

**Alternative écartée** : une promotion native par étiquette. Elle est réservée à l'édition Pro.

**Conclusion** : republication contrôlée. Les écarts avec la spécification sont listés dans [nexus/README.md](2-pipeline-livraison/registry/README.md).

---

## 8. Deux environnements, deux ports

**Décision** : le reverse proxy écoute sur 8070 en intégration et sur 9080 en production. Le port 8080, retenu au départ, est déjà pris sur le Mac Mini (cAdvisor et un tunnel SSH).

**Raisons**
- Éviter les ports privilégiés sur macOS : le port 80 exige les droits administrateur, ce qui complique Homebrew et le LaunchAgent.
- Ces ports sont distincts, donc les deux environnements peuvent coexister sur le même hôte.

**Alternative écartée** : le port 80. Il est réaliste en production, mais alourdit le déploiement local.

**Conclusion** : 8070 pour l'intégration, 9080 pour la production. Vérifier qu'un port est libre (`lsof -nP -iTCP:<port> -sTCP:LISTEN`) avant d'en attribuer un.

---

## 9. Pas de TLS

**Décision** : les échanges se font en HTTP, en local.

**Raisons**
- Le TLS est hors périmètre de la maquette.
- HTTP suffit pour les tests en local.
- Caddy sait gérer TLS, il pourra être activé plus tard.

**Conclusion** : HTTP uniquement.

---

## 10. Trois tiers séparés

**Décision** : le conteneur applicatif, le reverse proxy natif et la base native sont trois processus distincts.

**Raisons**
- Un monolithe serait plus simple, mais ne montrerait pas l'orchestration de plusieurs types de services par Ansible.
- Trois tiers permettent d'illustrer le réseau (conteneur vers base), le redémarrage de trois services et un contrôle de santé qui exige que les trois répondent.

**Conclusion** : trois tiers séparés. Voir [architecture.md](architecture-3tiers.md).

---

## 11. Pas de grappe, pas de répartition de charge

**Décision** : un seul hôte macOS, une seule instance de chaque tier.

**Raisons**
- La haute disponibilité est hors périmètre.
- L'orchestration sur une seule machine suffit à la démonstration.

**Conclusion** : une instance par tier et par environnement.

---

## 12. Documentation dans le dépôt du projet

**Décision** : la documentation vit dans `factice/Docs/`, à côté du code.

**Raisons**
- factice est un dépôt indépendant, avec ses propres rôles Ansible.
- La documentation évolue avec le code qu'elle décrit.

**Conclusion** : documentation, rôles et code applicatif dans le même dépôt.

---

## 13. Trunk-based development

**Décision** : une seule branche longue, `main`. Les changements passent par des branches courtes, fusionnées au plus tôt. Pas de branche `develop`, pas de branche par environnement.

**Raisons**
- La chaîne promeut un artefact immuable : l'état d'un environnement se lit dans Nexus (candidat, release, empreinte), pas dans une branche.
- Le contrôle de provenance de la promotion n'accepte que les commits de `main`.
- Moins de branches longues, donc moins de conflits de fusion et un retour d'information plus rapide.

**Alternative écartée** : Gitflow (`develop`, `release/*`, `hotfix/*`). Il duplique l'information déjà portée par les dépôts Nexus et retarde l'intégration.

**Conclusion** : trunk-based. Règles détaillées dans [trunk-based.md](trunk-based.md).

---

## 14. Capitalisation systématique : incident, fiche KB, ITSM

**Décision** : tout incident ou correctif laisse une fiche dans [kb.md](kb.md), dans le même push que le correctif. Un déploiement en échec ouvre un incident dans l'ITSM ; l'incident ne se clôt en succès qu'une fois rattaché à une fiche. Le job `kb-check` refuse un commit `fix` sans fiche.

**Raisons**
- Sans contrôle, la fiche est oubliée : le même piège a coûté trois runs (KB-002, KB-005).
- Le lien ITSM ↔ KB rend la connaissance retrouvable depuis l'incident, c'est le flux 13-14 de [flux-outils-factice.md](1-fondations/flux-outils-factice.md).

**Alternative écartée** : une règle de revue seule. Elle ne tient pas sur un projet à un seul contributeur.

**Limite** : le contrôle vérifie la présence d'une fiche, pas sa qualité ; la rédaction reste humaine.

---

## 15. Exigences, preuves et notes de version dans le pipeline

**Décision** : un commit `feat` ou `fix` cite une exigence de `Docs/exigences/` (ou déclare `Exigence: non-applicable`) ; les tests nommés d'après une exigence produisent un rapport de preuves à chaque run ; la promotion génère les notes de version (changements, exigences, fiches KB, preuves) ; le rapprochement registry / CMDB tourne chaque jour et ouvre un incident sur écart.

**Raisons**
- Flux 1, 6, 7 et 11 de [flux-outils-factice.md](1-fondations/flux-outils-factice.md) : sans contrôle automatique, le lien exigence ↔ code ↔ preuve se perd.
- Les contrôles réutilisent le patron de la décision 14 : un script testable en local, un job qui l'appelle.

**Limite** : le contrôle vérifie qu'une exigence existante est citée, pas qu'elle est pertinente. Le rapport de preuves ne couvre que les tests nommés d'après une exigence.
