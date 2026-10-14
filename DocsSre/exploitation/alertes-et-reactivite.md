# Alertes et réactivité

## Politique d'alerte

Toute alerte doit satisfaire :
1. **Signal fort** : metric baseline établie + seuil clair (déviation, ratio, délai)
2. **Action claire** : runbook lié, pas d'alerte sans remède
3. **Récurrence contrôlée** : pas de spam (escalade si > 5 min non résolue)

## Règles d'alerte Prometheus

### Alerte 1 : Tier App down

```promql
up{job="factice-app"} == 0
```

- **Condition** : scrape échoue 2x consécutives (120 secondes)
- **Severity** : 🔴 critical
- **Runbook** : `/docs/runbooks/tier-app-down.md`
- **Action** : SSH sur l'hôte, vérifier logs Docker

### Alerte 2 : Latence dégradée

```promql
histogram_quantile(0.95, factice_app_request_duration_seconds) > 0.500
```

- **Condition** : p95 > 500ms pendant 5 min
- **Severity** : 🟡 warning
- **Runbook** : `/docs/runbooks/latency-high.md`
- **Action** : Vérifier requêtes lentes BD, charge CPU

### Alerte 3 : Taux d'erreur élevé

```promql
rate(factice_app_errors_total[5m]) > 0.001
```

- **Condition** : > 0.1 % d'erreurs 5xx pendant 5 min
- **Severity** : 🟡 warning
- **Runbook** : `/docs/runbooks/error-rate-high.md`
- **Action** : Vérifier logs applicatifs, santé PostgreSQL

### Alerte 4 : Espace disque bas

```promql
node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} < 0.2
```

- **Condition** : < 20 % d'espace disque libre
- **Severity** : 🟡 warning
- **Runbook** : `/docs/runbooks/disk-space-low.md`
- **Action** : Nettoyer images Docker, logs, snapshots Nexus

### Alerte 5 : PostgreSQL non réactif

```promql
up{job="factice-postgres"} == 0
```

- **Condition** : PostgreSQL ne répond pas
- **Severity** : 🔴 critical
- **Runbook** : `/docs/runbooks/postgres-down.md`
- **Action** : SSH, vérifier `brew services list`, logs PostgreSQL

## Escalade et notification

| Severity | Délai | Destinataire | Médium |
|---|---|---|---|
| 🔴 critical | Immédiat | On-call + team lead | Slack #incidents |
| 🟡 warning | 5 min | Team lead | Slack #alerts |
| 🔵 info | 1 h | Logs Grafana | Dashboard |

## SLO de réactivité (en route)

| Objectif | Cible |
|---|---|
| Détection alerte | < 2 min après seuil atteint |
| Ack incident | < 5 min (on-call) |
| Remédiation | < 30 min pour warning, < 10 min pour critical |
| Post-mortem | < 24 h (critique), < 1 week (warning) |

## Prochaines étapes

1. Déployer AlertManager Prometheus
2. Intégrer webhooks Slack / PagerDuty
3. Écrire 5 runbooks de base
4. Tester alertes en déploiement intégration
