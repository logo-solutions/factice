# Nexus Repository : gouvernance des artefacts

| Document | Contenu |
|---|---|
| [dossier-architecture-nexus.md](dossier-architecture-nexus.md) | Dossier d'architecture v5 : décisions D1 à D7, options A et B, exemple monex.diagb / monex.jira |
| [presentation-nexus-directeur.md](presentation-nexus-directeur.md) | Présentation de 10 slides pour un directeur, avec notes orateur |
| [spec-implementation-nexus.md](spec-implementation-nexus.md) | Spécification technique d'implémentation : dépôts, droits, cycle de vie, événement de déploiement, recette |

## Mise en œuvre dans la maquette

| Élément | Emplacement |
|---|---|
| Rôle Ansible (dépôts, blob stores, nettoyage, droits, tâches, conformité) | `roles/nexus/`, lancé par `provision-nexus.yml` |
| Publication en candidat, promotion, événement de déploiement, SBOM | `scripts/nexus/` |
| Recette R1, R2, R3, R4, R8, R11 | `scripts/nexus/recette.sh` |
| Contrat de la chaîne de build | `.github/workflows/ci.yml` |

Provisionnement d'une instance existante (configuration seule) :

```
ansible-playbook provision-nexus.yml -e nexus_manage_container=false \
  -e nexus_container_name=nexus -e nexus_admin_password=<secret> \
  -e nexus_eula_accepted=true
```

Les mots de passe des comptes de service sont générés dans `.secrets/nexus/` (hors dépôt) puis chargés dans les secrets GitHub `NEXUS_BUILD_PASSWORD`, `NEXUS_PROMOTION_PASSWORD`, `NEXUS_DEPLOY_PASSWORD`.

### Écarts connus avec la spec (Community Edition)

| Spec | Maquette | Raison |
|---|---|---|
| Promotion native par étiquette | Republication contrôlée par empreinte (image identique octet pour octet, manifeste et SBOM copiés) | Pas de staging natif en Community ; point 12 de la spec |
| Étiquette `build` | Champ `build` du manifeste | Étiquettes (tags) réservées à Pro |
| Analyse licences et vulnérabilités, quarantaine (R5) | Non couverte | Pare-feu de dépôt absent de Community |
| SSO annuaire, haute disponibilité (R10) | Non couverts | Fonctions Pro |
| Sous-domaine par dépôt Docker | Un port par dépôt (5001 à 5004) | Pas de répartiteur de charge dans la maquette |
| CMDB (R7, R9) | Événement journalisé dans `deploy-events.jsonl`, envoyé si `CMDB_EVENT_URL` est défini | Pas de CMDB dans la maquette |
| Candidat immuable | Candidat réécrivable (`ALLOW`), release immuable (`ALLOW_ONCE`) | Un rebuild du même commit remplace le candidat |
