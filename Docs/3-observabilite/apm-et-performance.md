# APM et performance

## Application Performance Monitoring (APM)

Factice collecte les métriques applicatives pour identifier les goulots d'étranglement.

## Instrumentation Node.js

### Métriques exposées

L'application Node.js expose un endpoint `/metrics` au format Prometheus :

```javascript
// app.js exemple
const promClient = require('prom-client');

const httpDuration = new promClient.Histogram({
  name: 'factice_http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1.0],
});

const httpRequests = new promClient.Counter({
  name: 'factice_http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpDuration.labels(req.method, req.route.path, res.statusCode).observe(duration);
    httpRequests.labels(req.method, req.route.path, res.statusCode).inc();
  });
  next();
});

app.get('/metrics', (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(promClient.register.metrics());
});
```

## Profiling des requêtes lentes

### Query analytics PostgreSQL

Activer log des requêtes lentes :

```sql
-- postgresql.conf
log_min_duration_statement = 100  -- Log requêtes > 100ms
log_statement = 'all'  -- Log toutes les requêtes (dev only)
```

Analyse des requêtes lentes :

```sql
SELECT query, calls, mean_time 
  FROM pg_stat_statements 
  ORDER BY mean_time DESC 
  LIMIT 10;
```

### Profiling Node.js (node --prof)

Pour une investigation locale :

```bash
node --prof app.js
# [Générer du trafic avec ab ou curl]
node --prof-process isolate-0x....log > profile.txt
# Analyser results
```

## Charges et benchmarks

### Bench suite (vegeta ou Apache Bench)

Exécuter tous les 3 mois :

```bash
# Requêtes GET /items (lecture)
ab -n 10000 -c 50 http://localhost:8080/items

# Requêtes POST /items (écriture)
echo "POST http://localhost:8080/items" | vegeta attack -duration=60s -rate=100 | vegeta report
```

Documenter :
- Requêtes/sec max
- Latence p50, p95, p99
- Taux d'erreur sous charge

### Mémoire et CPU

Surveil le conteneur App :

```bash
docker stats --no-stream maisonnettev2-app-integration
```

Objectifs :
- CPU : < 20 % (repos), < 80 % (pic)
- RAM : < 200 MB (repos), < 500 MB (pic)

## Optimisation

### Indicateurs de performance

| Indicateur | Baseline | Cible | Action si dépassement |
|---|---|---|---|
| Latence p95 GET /items | 50ms | 200ms | Indexer requête BD, cacher réponses |
| Latence p95 POST /items | 100ms | 300ms | Optimiser transaction BD |
| CPU sous 100 req/s | 10 % | 30 % | Profiler (node --prof) |
| RAM utilisée | 150 MB | 300 MB | Analyser fuite mémoire (heap dump) |

### Heap dump (investigation)

Si fuite mémoire suspecte :

```bash
docker exec maisonnettev2-app-integration kill -USR2 $(docker inspect -f '{{.State.Pid}}' maisonnettev2-app-integration)
# Heap dump généré dans le conteneur
docker cp maisonnettev2-app-integration:/path/to/heapsnapshot .
# Analyser dans Chrome DevTools
```

## SLO performance

| SLI | Cible | Fenêtre | Remarques |
|---|---|---|---|
| Latence p95 | 200ms | 1 heure | Incluant réseau et BD |
| Latence p99 | 500ms | 1 heure | Cas pathologiques |
| Disponibilité | 99.5 % | 7 jours | Hors maintenance |

## Prochaines étapes

1. Instrumenter Node.js avec prom-client
2. Configurer scrape Prometheus `/metrics`
3. Créer dashboard Grafana "Performance Analysis"
4. Établir baselines (requêtes/sec, latence)
5. Planifier benchmarks trimestriels
