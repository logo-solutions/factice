# Logs et traces distribuées

## Stratégie de log

Tous les logs factice sont redirigés vers un système centralisé (Grafana Loki ou ELK).

### Sources de log

| Source | Format | Niveau | Archivage |
|---|---|---|---|
| **Ansible playbooks** | JSON (stdout) | INFO | Vault ou S3 |
| **Tier Web (Caddy)** | JSON (access.log) | INFO | Loki (7 jours) |
| **Tier App (Node.js)** | JSON (Winston) | INFO/DEBUG | Loki (7 jours) |
| **Tier BDD (PostgreSQL)** | CSV (slow query log) | query > 100ms | Loki (1 jour) |
| **Docker daemon** | JSON | ERROR | Loki (3 jours) |

### Format unifié

Tous les logs sont structurés en JSON :

```json
{
  "timestamp": "2026-10-02T14:32:15Z",
  "service": "factice-app",
  "environment": "production",
  "level": "INFO",
  "message": "GET /items",
  "request_id": "req-12345",
  "duration_ms": 42,
  "status_code": 200,
  "user_id": null,
  "trace_id": "trace-12345"
}
```

## Logs par tier

### Tier Web (Caddy)

Log chaque requête HTTP :

```
factice-web 2026-10-02T14:32:15Z GET /health 200 2ms 100.1.2.3
```

### Tier App (Node.js)

Log chaque route :

```json
{
  "timestamp": "...",
  "service": "factice-app",
  "level": "INFO",
  "message": "POST /items",
  "duration_ms": 15,
  "status": 201,
  "trace_id": "..."
}
```

En cas d'erreur :

```json
{
  "level": "ERROR",
  "message": "DB connection failed",
  "error": "ECONNREFUSED 127.0.0.1:5432",
  "stack": "..."
}
```

### Tier BDD (PostgreSQL)

Capture les requêtes lentes (> 100ms) :

```
duration: 120.5 ms  statement: SELECT * FROM items WHERE id = $1
```

## Traces distribuées (OpenTelemetry)

Optionnel mais recommandé : instrumenter une requête end-to-end :

```
[Client] 
  ↓ (trace-id: abc123)
[Tier Web - Caddy] logs trace-id
  ↓ 
[Tier App - Node.js] logs trace-id
  ↓ 
[Tier BDD - PostgreSQL] logs trace-id
```

Chaque log comporte `trace_id=abc123` → traçabilité end-to-end dans Loki.

## Interrogation des logs (Loki)

### Exemple 1 : Toutes les erreurs 5xx

```logql
{service="factice-app", level="ERROR"} | status_code >= 500
```

### Exemple 2 : Latence > 500ms

```logql
{service="factice-app"} | json | duration_ms > 500
```

### Exemple 3 : Logs d'une trace

```logql
{trace_id="trace-12345"}
```

## Rétention

| Source | Rétention | Archivage |
|---|---|---|
| Logs applicatifs (Loki) | 7 jours | S3 (30 jours) |
| Logs Ansible | 30 jours | Git histoire |
| Logs PostgreSQL (slow query) | 1 jour | Grafana datasource |

## Prochaines étapes

1. Déployer Grafana Loki
2. Configurer Promtail sur l'hôte (scrape docker logs, syslog)
3. Instrumenter Node.js avec winston JSON logger + trace-id
4. Créer dashboards "Logs by service" et "Error analysis"
