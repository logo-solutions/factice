# AHRA : stories d'industrialisation de la livraison

Projet distinct de factice. Stories rédigées à partir des échanges du 28/10/2026, complétées avec les exigences de sécurité applicables (OF-xx et mesures ReCyF).

## Décisions retenues

- **Cible de déploiement** : cloud privé.
- **Environnement d'intégration** : ICAT.
- **Application actuelle** : AHRA, sur Exadata, livrables compilés.
- **Procédure actuelle** : scripts shell lancés à la main.
- **POC** : sur « Brique Référentielle », application plus simple que AHRA.
- **Repo OIGL** : sur une instance Nexus dédiée à AHRA, distincte de celle de factice.
- **Runner** : éphémère (un environnement jetable par job).
- **Snapshot ICAT** : snapshot de VM ou de volume, à froid (VM arrêtée), avec données anonymisées.
- **Environnements à partir du snapshot** : par clonage de volume.
- **Cadre RH** : hors périmètre pour l'instant.

## Exigences de sécurité applicables

Source : exigences officielles ReCyF, recommandations ANSSI DevSecOps et mesures ReCyF v2.5 (document de travail).

| Exigence | Nature | Ce qu'elle impose à AHRA | Stories |
|---|---|---|---|
| OF-03 | Recommandation ANSSI | Séparer les infrastructures CI/CD de développement et de production, sans exposition directe sur Internet | 4, 7, 13 |
| OF-08 | Recommandation ANSSI | Traiter les actions de la CI/CD de production comme des actions d'administration | 7, 11 |
| OF-09 | Recommandation ANSSI | Dédier un poste d'administration à la CI/CD de production | 11 |
| OF-10 | Recommandation ANSSI | Moindre privilège, jetons générés à la demande | 5, 7, 10 |
| OF-11 | Recommandation ANSSI | Journaliser et superviser la CI/CD de production | 12 |
| OF-13 (11.A.6, 11.A.7-EE) | Obligatoire en EE | Liste à jour des comptes d'administration, droits restreints à chaque modification, via des groupes | 5, 10 |
| OF-30 | Recommandation ANSSI | Un gestionnaire de secrets distinct par environnement | 4.3, 13 |
| 19.1 à 19.8-EE | Obligatoire en EE | Réseau d'administration dédié, cloisonné et filtré | 11 |
| 20.1, 20.4 à 20.6-EE | Obligatoire en EE | Collecte, conservation d'au moins trois mois, copie hors ligne, traitement sous 24 h | 12 |
| 10.B.3-EI/EE | Obligatoire | Renouvellement des secrets partagés au départ d'un utilisateur | 13 |

## Epic : Industrialisation de la livraison AHRA

### 1. Retravailler la procédure manuelle
En tant que core team, je veux remplacer les scripts shell lancés à la main sur AHRA par une procédure reproductible, afin que le déploiement ne dépende plus d'une personne ni de l'ordre d'exécution.
- Critère de fermeture : la procédure est décrite étape par étape dans un runbook relu, et chaque étape a une vérification.
- Critères d'acceptation :
  - [ ] Inventaire de tous les scripts shell et de leur ordre d'exécution actuel
  - [ ] Étapes propres à l'Exadata et aux livrables compilés identifiées séparément
  - [ ] Points de risque (arrêts de service, retours arrière) listés
  - [ ] Runbook validé par une seconde personne
  - [ ] Le runbook précise sur quel poste d'administration (story 11) chaque étape est exécutée
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
  - [ ] Journal d'exécution : qui, quoi, où, quand, résultat (exigé par la story 12)
  - [ ] Secrets lus dans Ansible Vault, jamais en clair, avec un vault ID propre à l'environnement (story 13)

### 4. POC Ansible sur Brique Référentielle, environnement d'intégration
En tant que core team, je veux valider la chaîne complète (runner, Ansible, Vault) sur Brique Référentielle, afin de corriger les problèmes avant AHRA.

- **4.1 Runner GitLab éphémère sur l'intégration**
  - Critère de fermeture : un job de test tourne sur ce runner, sans intervention manuelle.
  - [ ] Environnement jetable par job, détruit en fin de job
  - [ ] Aucune donnée ni secret ne persiste entre deux jobs
  - [ ] Le runner d'intégration ne partage aucun identifiant avec le runner de production (OF-03, story 13)
  - [ ] Les journaux du job sont exportés vers le point de collecte pendant l'exécution, et non stockés sur le runner (story 12)

- **4.2 Ansible installé et versionné**
  - Critère de fermeture : un playbook de test s'exécute depuis le runner.
  - [ ] Version d'Ansible figée et documentée

- **4.3 Ansible Vault en place**
  - Critère de fermeture : un secret chiffré est déchiffré par le playbook de test, et un scan ne trouve aucun secret en clair.
  - [ ] Clé de chiffrement hors dépôt, dans le coffre
  - [ ] Un vault ID par environnement, avec son propre mot de passe (story 13)
  - [ ] Découpage (par application ou par environnement) tranché avant la rédaction du playbook

### 5. Repo OIGL en lecture-écriture, sur l'instance Nexus AHRA
En tant que core team, je veux un repository OIGL en lecture-écriture sur l'instance Nexus dédiée à AHRA, avec des comptes de service dédiés, afin que les pipelines publient et récupèrent leurs artefacts.
- Critère de fermeture : un compte de service publie et lit, et un compte sans droit est refusé.
- Critères d'acceptation :
  - [ ] Compte en écriture pour la publication, compte en lecture pour le déploiement
  - [ ] Aucun compte administrateur dans la configuration des pipelines
  - [ ] Blob store dédié, avec quota souple
  - [ ] Les deux comptes de service figurent dans le registre des comptes d'administration (story 10), avec leur groupe de droits
  - [ ] Jetons générés à la demande, et non stockés en clair (OF-10)

### 6. Installer VS Code depuis le portail IT
En tant que développeur, je veux VS Code installé depuis le portail IT, afin de travailler avec les outils validés.
- Critère de fermeture : VS Code démarre sur le poste cible.
- Critères d'acceptation :
  - [ ] Installation depuis le portail, sans téléchargement externe
  - [ ] Version conforme au catalogue

### 7. Déployer AHRA avec Ansible, depuis un runner de production éphémère
En tant que core team, je veux déployer AHRA avec Ansible depuis un runner de production éphémère, lancé depuis le poste d'administration dédié, afin de sortir du déploiement manuel.
- Critère de fermeture : AHRA est déployé sur la cible depuis la CI, sans intervention manuelle, et la version déployée est identifiable.
- Critères d'acceptation :
  - [ ] Playbook reprenant les étapes validées de la story 1
  - [ ] Version déployée tracée, avec son empreinte
  - [ ] Journal d'exécution conforme à la story 3 et à la story 12
  - [ ] Le déploiement en production n'est lancé que depuis le réseau d'administration (story 11)
  - [ ] Le runner de production ne partage aucun identifiant avec celui d'intégration (OF-03, story 13)
- Dépendances : stories 1, 2, 3, 4.1, 11, 12, 13.

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

### 10. Tenir le registre des comptes d'administration
En tant que responsable de la sécurité, je veux un registre à jour des comptes d'administration, avec leurs droits restreints et attribués par groupe, afin de satisfaire OF-13 et 11.A.6-EE.
- Critère de fermeture : le registre est publié, chaque compte y figure, et une modification de compte y est tracée.
- Critères d'acceptation :
  - [ ] Comptes de service (publication, déploiement, exécution Ansible, pipelines), comptes administrateurs de Nexus et administrateurs du coffre inscrits
  - [ ] Pour chaque compte : propriétaire nommé, périmètre, groupe de droits, date de dernière revue
  - [ ] Toute création, modification ou suppression de compte est tracée avec sa date
  - [ ] Revue au moins annuelle (mesure 10.C.4)
  - [ ] Droits attribués par groupe, et non compte par compte

### 11. Poste d'administration dédié à la CI/CD de production
En tant que responsable de la sécurité, je veux un poste dédié à l'administration de la CI/CD de production, afin que les déploiements en production ne partent que d'un poste maîtrisé (OF-08, OF-09, 19.1 à 19.8).
- Critère de fermeture : le déploiement de production est lancé uniquement depuis ce poste, et une tentative depuis un autre poste est refusée.
- Critères d'acceptation :
  - [ ] Poste ou VM réservée à cet usage, sans navigation ni messagerie
  - [ ] Accès au réseau d'administration dédié, cloisonné et filtré (19.1, 19.8)
  - [ ] Poste durci selon les recommandations ANSSI (19.6), ou poste physique dédié si la décision le retient
  - [ ] Liste des personnes autorisées à s'y connecter, dans le registre (story 10)
- Point à trancher : poste physique ou VM ; le passage en EE impose un poste physique dédié (19.4), ce qui change le coût.

### 12. Journaliser et superviser la CI/CD de production
En tant que responsable de la sécurité, je veux que chaque job de production soit journalisé et supervisé, y compris lorsque le runner est détruit, afin de satisfaire OF-11 et les mesures 20.1, 20.4 à 20.6.
- Critère de fermeture : un déploiement de test produit une trace complète, lisible au point central de collecte, et cette trace survit à la destruction du runner.
- Critères d'acceptation :
  - [ ] Journaux exportés vers le point central pendant l'exécution du job, avant destruction du runner
  - [ ] Chaque entrée identifie le job, le pipeline, le commit, l'auteur et le runner
  - [ ] Conservation d'au moins trois mois pour la production (20.5), avec copie hors ligne (20.6)
  - [ ] Événements de production traités sous 24 h ouvrées au plus (20.1)
- Point à trancher : point central de collecte (SIEM existant ou stockage dédié) et lecteurs des alertes.

### 13. Séparer les secrets et les runners entre développement et production
En tant que responsable de la sécurité, je veux des secrets et des runners distincts entre intégration et production, afin qu'un identifiant de développement ne puisse jamais atteindre la production (OF-03, OF-30).
- Critère de fermeture : un job d'intégration ne peut ni lire ni déchiffrer un secret de production, et un test de tentative est refusé.
- Critères d'acceptation :
  - [ ] Runners d'intégration et de production distincts, avec des tags distincts
  - [ ] Un vault ID par environnement, avec un mot de passe propre à chaque environnement (story 4.3)
  - [ ] Mot de passe de production uniquement dans les variables protégées du runner de production, ou dans le coffre
  - [ ] Administrateur du coffre de production distinct de l'équipe qui gère les runners (à valider avec le RSSI)
  - [ ] Renouvellement des secrets partagés au départ d'un utilisateur (10.B.3)
- Point à trancher : Ansible Vault suffit-il, ou faut-il un coffre externe par environnement ?

