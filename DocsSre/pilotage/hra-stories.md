# AHRA : stories d'industrialisation de la livraison

Projet distinct de factice. Stories rédigées à partir des échanges du 28/10/2026.

## Décisions retenues

- **Cible de déploiement** : cloud privé.
- **Environnement d'intégration** : ICAT (ancien ICAT).
- **Application actuelle** : AHRA, sur Exadata, livrables compilés.
- **Procédure actuelle** : scripts shell lancés à la main.
- **POC** : sur « Brique Référentielle », application plus simple que AHRA.
- **Repo OIGL** : sur une instance Nexus dédiée à AHRA, distincte de celle de factice.
- **Runner** : éphémère (un environnement jetable par job).
- **Snapshot ICAT** : snapshot de VM ou de volume, à froid (VM arrêtée), avec données anonymisées.
- **Environnements à partir du snapshot** : par clonage de volume.
- **Cadre RH** : hors périmètre pour l'instant.

## Epic : Industrialisation de la livraison AHRA

### 1. Retravailler la procédure manuelle
En tant que core team, je veux remplacer les scripts shell lancés à la main sur AHRA par une procédure reproductible, afin que le déploiement ne dépende plus d'une personne ni de l'ordre d'exécution.
- Critère de fermeture : la procédure est décrite étape par étape dans un runbook relu, et chaque étape a une vérification.
- Critères d'acceptation :
  - [ ] Inventaire de tous les scripts shell et de leur ordre d'exécution actuel
  - [ ] Étapes propres à l'Exadata et aux livrables compilés identifiées séparément
  - [ ] Points de risque (arrêts de service, retours arrière) listés
  - [ ] Runbook validé par une seconde personne
- Dépendance : story 2.

### 2. Lister les assets de l'application
En tant que responsable de la livraison, je veux un inventaire des assets (fichiers de configuration, livrables compilés, sources, base de données), afin de savoir ce qui est versionné, publié ou sauvegardé.
- Critère de fermeture : tableau publié, avec pour chaque asset un type, un emplacement, un propriétaire et un mode de livraison.
- Critères d'acceptation :
  - [ ] Configurations, livrables, sources et base de données listés
  - [ ] Pour chaque asset : versionné dans Git, publié dans le repo OIGL, ou sauvegardé
  - [ ] Propriétaire nommé par asset

### 3. Playbook Ansible de déploiement sur ICAT (cible cloud privé)
En tant que core team, je veux un playbook qui ne fait que déployer une version donnée sur ICAT dans le cloud privé, afin de déployer de façon reproductible.
- Critère de fermeture : le playbook déploie une version sur ICAT, et un second passage ne modifie rien.
- Critères d'acceptation :
  - [ ] Périmètre limité au déploiement (pas de build, pas de publication)
  - [ ] Version passée en paramètre, empreinte vérifiée avant déploiement
  - [ ] Journal d'exécution : qui, quoi, où, quand, résultat
  - [ ] Secrets lus dans Ansible Vault, jamais en clair

### 4. POC Ansible sur Brique Référentielle, environnement d'intégration
En tant que core team, je veux valider la chaîne complète (runner, Ansible, Vault) sur Brique Référentielle, afin de corriger les problèmes avant AHRA.

- **4.1 Runner GitLab éphémère sur l'intégration**
  - Critère de fermeture : un job de test tourne sur ce runner, sans intervention manuelle.
  - [ ] Environnement jetable par job, détruit en fin de job
  - [ ] Aucune donnée ni secret ne persiste entre deux jobs

- **4.2 Ansible installé et versionné**
  - Critère de fermeture : un playbook de test s'exécute depuis le runner.
  - [ ] Version d'Ansible figée et documentée

- **4.3 Ansible Vault en place**
  - Critère de fermeture : un secret chiffré est déchiffré par le playbook de test, et un scan ne trouve aucun secret en clair.
  - [ ] Clé de chiffrement hors dépôt, dans le coffre

### 5. Repo OIGL en lecture-écriture, sur l'instance Nexus AHRA
En tant que core team, je veux un repository OIGL en lecture-écriture sur l'instance Nexus dédiée à AHRA, avec des comptes de service dédiés, afin que les pipelines publient et récupèrent leurs artefacts.
- Critère de fermeture : un compte de service publie et lit, et un compte sans droit est refusé.
- Critères d'acceptation :
  - [ ] Compte en écriture pour la publication, compte en lecture pour le déploiement
  - [ ] Aucun compte administrateur dans la configuration des pipelines
  - [ ] Blob store dédié, avec quota souple

### 6. Installer VS Code depuis le portail IT
En tant que développeur, je veux VS Code installé depuis le portail IT, afin de travailler avec les outils validés.
- Critère de fermeture : VS Code démarre sur le poste cible.
- Critères d'acceptation :
  - [ ] Installation depuis le portail, sans téléchargement externe
  - [ ] Version conforme au catalogue

### 7. Déployer AHRA avec Ansible via runner éphémère
En tant que core team, je veux déployer AHRA avec Ansible depuis un runner éphémère, afin de sortir du déploiement manuel.
- Critère de fermeture : AHRA est déployé sur la cible depuis la CI, sans intervention manuelle, et la version déployée est identifiable.
- Critères d'acceptation :
  - [ ] Playbook reprenant les étapes validées de la story 1
  - [ ] Version déployée tracée, avec son empreinte
  - [ ] Journal d'exécution conforme à la story 3
- Dépendances : stories 1, 2, 3, 4.1.

### 8. Snapshot à froid de l'intégration ICAT
En tant que responsable de la livraison, je veux un snapshot à froid de l'environnement ICAT (VM, base de données et application), avec des données anonymisées, afin de disposer d'une image de référence restaurable à l'identique.
- Critère de fermeture : le snapshot est créé, son intégrité est vérifiée, et un volume créé à partir de ce snapshot démarre une VM qui répond.
- Critères d'acceptation :
  - [ ] Anonymisation des données de la base effectuée avant le snapshot, et contrôlée
  - [ ] Arrêt de la VM ICAT pendant la prise de snapshot, avec durée d'indisponibilité mesurée et planifiée
  - [ ] Cohérence de la base vérifiée au redémarrage
  - [ ] Empreinte (checksum) du snapshot calculée et conservée
  - [ ] Snapshot identifié (version, date, source) et conservé selon la politique de rétention
- Point de vigilance : la fenêtre d'arrêt de ICAT doit être validée avec les équipes qui utilisent ICAT.

### 9. Créer des environnements à partir du snapshot, par volume
En tant que core team, je veux créer un environnement à partir du snapshot en clonant son volume, afin de reproduire ICAT à l'identique sans reconstruction manuelle.
- Critère de fermeture : un volume créé depuis le snapshot est attaché à une VM, démarre, et la comparaison avec ICAT ne montre aucun écart fonctionnel.
- Critères d'acceptation :
  - [ ] Playbook qui crée le volume depuis le snapshot, puis démarre la VM cible
  - [ ] Vérification de l'empreinte du snapshot avant clonage
  - [ ] Configuration propre à chaque cible (réseau, nom, paramètres) séparée du snapshot
  - [ ] Retour arrière : suppression du volume cloné, sans toucher au snapshot source
- Dépendances : stories 8 et 3.

