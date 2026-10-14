# Audit et conformité

## Audit trail

Chaque action déploiement / configuration est tracée immuablement :

### Sources d'audit

| Source | Contenu | Rétention |
|---|---|---|
| Git (commits) | Code, roles Ansible, configuration | Permanent |
| GitHub Actions | Build logs, déploiements, décisions | 30 jours |
| Ansible logs | Tâches exécutées, résultats | Vault ou S3 (1 an) |
| Nexus | Ingestion artefact, promotion, accès | 1 an |
| PostgreSQL audit log | DDL/DML, créateur, timestamp | 3 mois |
| Logs Caddy / App | Requêtes HTTP, erreurs | 7 jours |

### Requête d'audit typique

Qui a déployé la version X en production à la date Y ?

```
git log --grep="Deployed factice-production-v1.2.3" --format="%h %an %ai %s"
→ commit author, timestamp, message (contient version et environnement)

GitHub Actions run → links to commit, approver, timestamp

Nexus metadata → image digest, scan results, signer
```

## Conformité réglementaire

### Normes applicables

Factice ne traite pas de données sensibles (PII, santé, finances), donc applique des standards génériques :

- **ISO 27001** (Information Security Management) : baselines sécurité
- **ANSSI** (France) : recos "Expressions of Needs and Non-functional Requirements"
- **OWASP Top 10** : prévention vulnérabilités communes (injection, XSS, etc.)

### Checklist OWASP Top 10

| # | Risque | Mitigation factice |
|---|---|---|
| A1 | Injection SQL | Prisma ORM (parameterized queries) |
| A2 | Broken Authentication | N/A (pas d'authentification applicative) |
| A3 | Sensitive data exposure | HTTPS (Caddy + cert Let's Encrypt), pas de logs en clair |
| A4 | XML External Entities | N/A (pas de XML parsing) |
| A5 | Broken access control | API sans authentification (factice est interne) |
| A6 | Security misconfiguration | Playbooks Ansible codifiés, pas de drift |
| A7 | XSS | N/A (API JSON, pas de web UI) |
| A8 | Insecure deserialization | N/A (pas de sérialisation non sécurisée) |
| A9 | Using known vulnerable libraries | SAST + Nexus CVE scan + Dependabot |
| A10 | Insufficient logging & monitoring | Logs centralisés, alertes configurées |

### Checklist ANSSI

| Domaine | Recommandation | Status |
|---|---|---|
| Identité & Accès | MFA sur GitHub | ✅ Obligatoire |
| Chiffrement | TLS 1.3 pour HTTPS | ✅ Caddy default |
| Secrets | Vault + rotation | ✅ Ansible Vault |
| Audit | Traçabilité actions | ✅ Git + Ansible logs |
| Mise à jour | Patch OS + dépendances | 🔵 Planifié |
| Sauvegarde | Backup + test restoration | 🔵 PostgreSQL backup |
| Incident | Plan de réaction | 🔵 Runbooks requis |

## Scan CVE

### Nexus CVE Scan

Chaque push image déclenche scan CVE automatique :

```bash
# Exemple rapport
docker pull registry.nexus.example.com/factice:abc123
→ Image scanned by Nexus
→ Report: 0 critical, 2 high, 5 medium, 10 low
→ Block if critical found (policy)
```

### Dependabot (GitHub)

Scan les dépendances npm/node :

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: npm
    directory: "/"
    schedule:
      interval: weekly
    open-pull-requests-limit: 5
```

Crée des PRs automatiquement pour les mises à jour de sécurité.

### Code source (SAST)

SonarQube (optionnel, coût) ou tools gratuits :

```bash
# Exemple : npm audit
npm audit

# Exemple : Snyk
snyk test
```

## Conformité de configuration

### Ansible compliance

Chaque déploiement valide :

1. **Idempotence** : exécuter 2x doit produire `changed=0`
2. **Durcissement** : les rôles appliquent des standards (firewall, SELinux, etc.)
3. **Versionnement** : chaque playbook taguée avec version application

### Test de conformité

```bash
# Playbook de validation (post-déploiement)
- name: Validate compliance
  hosts: localhost
  tasks:
    - name: Check Caddy config is valid
      shell: caddy validate --config /etc/caddy/Caddyfile
      register: caddy_valid
    
    - name: Check PostgreSQL permissions
      postgresql_query:
        db: factice_production
        query: "SELECT usename FROM pg_roles WHERE usename = 'factice_production';"
      register: pg_user
    
    - assert:
        that:
          - caddy_valid.rc == 0
          - pg_user.query_result | length > 0
```

## KPI conformité

| Indicateur | Cible | Fréquence |
|---|---|---|
| Couverture CVE (vulns connues patched) | 100 % | Mensuel |
| Audit trail complète | 100 % | Continu |
| Déploiements approuvés (vs. manuels) | 100 % | Par déploiement |
| Incidents liés à sécurité | 0 | Annuel |
| Accès non-autorisé détectés | 0 | Continu |

## Rapport de conformité

Généré trimestriellement :

```
Factice Security Compliance Report — Q4 2026

✅ OWASP Top 10 : 10/10 points
   - Injection prevention: via Prisma ORM
   - Data encryption: HTTPS + Vault
   - Security logging: centralized (Loki)

✅ ANSSI : 7/10 points
   - Identity & access: MFA enforced
   - Secret management: Vault + rotation
   - TODO: Incident response playbook

⚠️  CVE scan results
   - High: 0
   - Medium: 2 (in dev deps, not production)
   - Low: 8 (low priority fixes)

✅ Audit trail: 100 % coverage

Recommendation: Add incident response runbook for Q1 2027
```

## Prochaines étapes

1. Intégrer npm audit en CI (fail if high/critical)
2. Configurer Snyk ou SonarQube
3. Créer checklist OWASP pour PRs
4. Planifier audit de conformité trimestriel
5. Documenter incident response plan
