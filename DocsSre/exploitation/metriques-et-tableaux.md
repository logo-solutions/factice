# Métriques et tableaux de bord

## Métriques clés de factice

Factice exposera des métriques au format Prometheus sur un port dédié :

| Métrique | Source | Fréquence | Utilité |
|---|---|---|---|
| `factice_app_requests_total` | Node.js (express) | 1 requête | Nombre total de requêtes |
| `factice_app_request_duration_seconds` | Node.js | 1 requête | Latence par route |
| `factice_app_errors_total` | Node.js | 1 erreur | Nombre d'erreurs 5xx |
| `factice_db_queries_total` | PostgreSQL | 1 requête | Nombre de requêtes BD |
| `factice_db_duration_seconds` | PostgreSQL slow query log | Par seuil | Requêtes > 100ms |
| `factice_container_memory_bytes` | Docker API | 10s | Consommation RAM du conteneur |
| `factice_container_cpu_percent` | Docker API | 10s | Utilisation CPU du conteneur |
| `node_filesystem_avail_bytes` | Prometheus node-exporter | 60s | Espace disque disponible |
| `node_memory_MemAvailable_bytes` | Prometheus node-exporter | 60s | RAM disponible sur l'hôte |

## Tableaux de bord (Grafana)

### Tableau 1 : Vue d'ensemble (SLA)

Affiche en temps réel :
- Statut 🟢/🟡/🔴 de chaque tier (Web, App, BDD)
- Taux de réussite des dernière 24h (target : ≥ 99.5 %)
- Nombre de déploiements depuis le dernier redémarrage

### Tableau 2 : Performances applicatives

- Latence p50, p95, p99 des routes GET /items, POST /items
- Erreurs 4xx vs 5xx par heure
- Requêtes lentes (> 100ms) vers PostgreSQL

### Tableau 3 : Ressources

- CPU / RAM / disque utilisés par le conteneur App
- Espace disque PostgreSQL
- Taux de remplissage du disque (alerte si > 80 %)

## Scrape Prometheus

Configurer dans Prometheus :

```yaml
scrape_configs:
  - job_name: 'factice-app'
    static_configs:
      - targets: ['localhost:3000/metrics']  # ou :3001 prod
        
  - job_name: 'factice-host'
    static_configs:
      - targets: ['localhost:9100']  # node-exporter
```

## Objectifs SLO

| SLI | Cible | Fenêtre | Remarques |
|---|---|---|---|
| Disponibilité | 99.5 % | 30 jours | Hors maintenance planifiée |
| Latence p95 | < 200ms | 30 jours | Requête GET /items |
| Taux d'erreur 5xx | < 0.1 % | 30 jours | Par rapport au total requêtes |

## Prochaines étapes

1. Configurer Prometheus + Grafana en local
2. Exporter les métriques Node.js (middleware express ou prom-client)
3. Créer le dashboard Grafana "Factice Overview"
4. Documenter les seuils d'alerte
