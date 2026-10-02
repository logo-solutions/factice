> **État réel.** Ce document décrit une cible générale ; plusieurs exemples ne correspondent pas à la mise en œuvre. Aujourd'hui : le workflow utilise les secrets `NEXUS_BUILD_PASSWORD`, `NEXUS_PROMOTION_PASSWORD`, `NEXUS_DEPLOY_PASSWORD` (un par compte de service) et passe le mot de passe par variable d'environnement ; le runner est auto-hébergé ; `vault.yml` contient des valeurs de remplacement **en clair**, non chiffrées ; aucune analyse de secrets n'est exécutée en CI. Voir [bonnes-pratiques-ansible.md](../2-pipeline-livraison/orchestration/bonnes-pratiques-ansible.md), section 6, et [securite-pipeline.md](../2-pipeline-livraison/ci-cd/securite-pipeline.md), section 9.

# Secrets et credentials

## Gestion centralisée des secrets

Tous les secrets factice sont stockés dans **Ansible Vault** (password manager encrypté en Git).

### Secrets à gérer

| Secret | Valeur | Utilisateur | Archivage |
|---|---|---|---|
| `db_password_integration` | PG user factice_integration | Ansible | Vault |
| `db_password_production` | PG user factice_production | Ansible | Vault |
| `nexus_username` | Compte lecture-seule Nexus | Ansible, CI/CD | Vault |
| `nexus_password` | Token Nexus | Ansible, CI/CD | Vault |
| `github_token` | Personal Access Token | CI/CD | GitHub Secrets |
| `docker_registry_url` | URL Nexus Docker registry | Ansible | Vault |
| `docker_registry_auth` | Base64(user:pass) | Docker `.auth.json` | Vault |

## Stockage Ansible Vault

### Fichier vault.yml

```yaml
# inventory/group_vars/local/vault.yml (encrypted)
vault_db_password_integration: "strong_password_12345"
vault_db_password_production: "another_strong_password_67890"
vault_nexus_username: "factice-ci-user"
vault_nexus_password: "nexus_token_abc123xyz"
vault_github_token: "ghp_xxxxxxxxxxxxxxxxxxxx"
vault_docker_registry_url: "registry.nexus.example.com"
vault_docker_registry_auth: "Zm...Og=="  # base64
```

### Chiffrement/déchiffrement

```bash
# Chiffrer le fichier
ansible-vault encrypt inventory/group_vars/local/vault.yml

# Déchiffrer (pour édition)
ansible-vault edit inventory/group_vars/local/vault.yml

# Lancer playbook avec vault
ansible-playbook site.yml --ask-vault-pass
# Ou via fichier vault password :
ansible-playbook site.yml --vault-password-file=.vault-pass
```

**⚠️ Règle critique** : `.vault-pass` n'est jamais commité. Il reste local ou en variables d'environnement CI.

## GitHub Secrets (CI/CD)

Les secrets CI/CD (tokens GitHub, Nexus) résident dans **GitHub Organization Secrets** :

| Secret | Valeur | Scope |
|---|---|---|
| `NEXUS_USERNAME` | factice-ci-user | Tous les workflows |
| `NEXUS_PASSWORD` | nexus_token_abc123xyz | Tous les workflows |
| `NEXUS_DOCKER_REGISTRY` | registry.nexus.example.com | Build + push images |

Workflow d'utilisation :

```yaml
# .github/workflows/ci.yml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Build Docker image
        run: |
          docker build -t myapp:${{ github.sha }} .
          echo ${{ secrets.NEXUS_PASSWORD }} | docker login -u ${{ secrets.NEXUS_USERNAME }} --password-stdin ${{ secrets.NEXUS_DOCKER_REGISTRY }}
          docker push ${{ secrets.NEXUS_DOCKER_REGISTRY }}/factice:${{ github.sha }}
```

## Rotation des secrets

### Calendrier de rotation

| Secret | Fréquence | Responsable | Processus |
|---|---|---|---|
| Mots de passe BD | Annuellement | DBA Ansible | 1. Générer nouveau | 2. Mettre à jour Vault | 3. Redéployer | 4. Tester accès |
| Tokens Nexus | Semestriellement | DevOps | 1. Régénérer dans Nexus | 2. Mettre à jour Vault + GitHub Secrets | 3. Redéployer |
| Tokens GitHub | Annuellement | Platform team | 1. Régénérer PAT | 2. Mettre à jour GitHub Secrets | 3. Vérifier CI |

### Audit des changements

Tout changement de secret est enregistré :

```bash
# Voir historique Vault
git log --oneline inventory/group_vars/local/vault.yml

# Qui a changé quoi ?
git show <commit>  # (contenu chiffré, mais commit message visible)
```

## Credential scanning en CI

Détecter les secrets accidentellement commités :

```yaml
# .github/workflows/secret-scan.yml
name: Secret Scan
on: [push, pull_request]
jobs:
  truffleHog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: TruffleHog Scan
        run: |
          pip install truffleHog
          truffle-hog git file://. --json
```

Si un secret est trouvé :
1. Invalider immédiatement (regénérer le token)
2. Réécrire l'historique Git (ou marquer commit comme "compromis")
3. Enquêter sur qui a accès aux secrets

## Principes de least privilege

| Service | Secret | Scope |
|---|---|---|
| CI/CD | Token Nexus (lecture-seule) | Push images candidat uniquement |
| Ansible | Token Nexus (lecture) | Pull images pour déploiement |
| App (Node.js) | Aucun (env vars immuables) | Pas de secrets dans l'app elle-même |
| PostgreSQL | Password utilisateur non-root | SELECT, INSERT, UPDATE sur base factice_* uniquement |

## Checklist secrets

- [ ] Aucun secret dans le repo (git grep password, token, secret)
- [ ] Vault file encrypté et `.vault-pass` en .gitignore
- [ ] GitHub Secrets configurés et non affichés en logs
- [ ] Credentials scanning en CI (TruffleHog ou similaire)
- [ ] Rotation planifiée et documentée
- [ ] Accès Vault limité (seuls Ansible runners et DevOps)

## Prochaines étapes

1. Initialiser `ansible-vault` avec password fort
2. Créer `inventory/group_vars/local/vault.yml` encrypté
3. Configurer GitHub Secrets
4. Intégrer credential scanning dans CI
5. Planner rotation semestrielle
