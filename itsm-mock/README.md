# Faux ITSM

Petit service REST qui simule le contrat d'un ITSM (changements, incidents) pour câbler et tester le pipeline factice **avant** d'avoir un vrai outil (GLPI, GitLab, ServiceNow, etc.). Le pipeline ne parle jamais au service directement : il passe par l'adaptateur `scripts/itsm/itsm.sh`. Passer à un vrai ITSM = réécrire cet adaptateur, rien d'autre.

Aucune dépendance (Node 20, `node:http`). Données dans un fichier JSON (`changes.json`). Voir `Docs/1-fondations/flux-outils.md` (flux 2, 10, 12) et `Docs/exigences/10-controle-acces-segregation.md` (ACC-04, ACC-07).

## Contrat

| Opération | Adaptateur | API | Droit |
|---|---|---|---|
| Créer | `create <type> <titre> [description] [env]` | `POST /changes` | `create` |
| Lire l'état | `status <ID>`, `show <ID>`, `list [état]` | `GET /changes[/:id]` | `read` |
| Approuver / refuser | `approve <ID>`, `reject <ID> <motif>` | `POST /changes/:id/approve\|reject` | `approve` |
| Lier un déploiement | `link <ID> <empreinte> [run_url] [env] [ci_url]` | `POST /changes/:id/link` | `link` |
| Clore | `close <ID> <succes\|echec>` | `POST /changes/:id/close` | `close` |
| Garde de déploiement | `require-approved <ID>` (code 3 si non approuvé) | `GET /changes/:id` | `read` |

Types : `standard` (pré-approuvé à la création), `normal` (brouillon, approbation humaine), `incident` (ouvert, sans déploiement).
États : `brouillon` → `approuve` | `refuse` → `en_cours` (après `link`) → `clos`. Un incident va de `ouvert` à `clos`.

Règles simulées :
- le demandeur est l'identité du jeton, jamais une valeur du corps de requête ;
- l'approbateur doit être différent du demandeur (ACC-04) ;
- on ne peut pas lier un déploiement avant approbation (409) ;
- chaque demande garde son `historique` (qui, quand, quoi).

## Jetons et rôles (ACC-07)

Variable `ITSM_TOKENS`, format `jeton:identité:droit,droit;jeton:identité:droit`. Droits : `read`, `create`, `approve`, `link`, `close`. Le service refuse de démarrer sans jetons : aucun secret par défaut.

```bash
export TP=$(openssl rand -hex 24)   # pipeline
export TA=$(openssl rand -hex 24)   # approbateur humain
export ITSM_TOKENS="$TP:pipeline:read,create,link,close;$TA:loic:read,approve"
```

Ne jamais committer ces valeurs : en CI, les stocker comme secrets du dépôt.

## Lancer

```bash
# tests
cd itsm-mock && npm test

# local
ITSM_TOKENS="$ITSM_TOKENS" node server.js          # http://127.0.0.1:8095

# Docker (Mac Mini), port lié à 127.0.0.1 uniquement
ITSM_TOKENS="$ITSM_TOKENS" docker compose up -d --build
```

## Démo

```bash
export ITSM_TOKEN=$TP
ID=$(scripts/itsm/itsm.sh create normal "Déploiement production" "release 1.4" production)
scripts/itsm/itsm.sh require-approved "$ID"   # code 3 : brouillon
ITSM_TOKEN=$TA scripts/itsm/itsm.sh approve "$ID"
scripts/itsm/itsm.sh require-approved "$ID"   # code 0
scripts/itsm/itsm.sh link "$ID" sha256:abc1234 "https://github.com/…/runs/1" production
scripts/itsm/itsm.sh close "$ID" succes
```

## Brancher sur `deploy-production`

Exemple à insérer avant l'étape de déploiement (l'ID du changement est un `inputs` du workflow manuel) :

```yaml
- name: Vérifier l'approbation dans l'ITSM
  env:
    ITSM_URL: ${{ secrets.ITSM_URL }}
    ITSM_TOKEN: ${{ secrets.ITSM_TOKEN }}
  run: scripts/itsm/itsm.sh require-approved "${{ inputs.change_id }}"
```

Puis `link` après le déploiement (empreinte de l'image) et `close` avec le résultat. L'environnement protégé GitHub reste le blocage technique (décision 1) ; l'ITSM garde la trace.

## Limites

Pas d'interface web d'approbation (on approuve en ligne de commande ou par API), pas de CMDB (flux 10 et 12 hors périmètre), pas de TLS (à placer derrière Caddy si exposé), pas de multi-instance. Ce n'est pas un ITSM, c'est un double de test du contrat.
