# ADR-0005 — Routage des dépôts Docker : un sous-domaine par dépôt et par groupe

- **Statut** : proposé le 15/10/2026, en attente d'acceptation.
- **Exigences liées** : spec `nexus-spec.md` §3.3 (point d'accès distinct par dépôt Docker), §4 (règle de chemin), §5.3 (TLS obligatoire de bout en bout), §12 (routage Docker à figer). Démos S1, S6 et S11 de `nexusus.md`.
- **Références** :
  - OCI Distribution Spec (API de registre) : les clients Docker appellent `/v2/` à la racine de l'hôte ; un registre n'est pas prévu pour vivre sous un préfixe de chemin.
  - Documentation Sonatype Nexus Repository : un dépôt Docker s'expose par un connecteur HTTP dédié (port) ou par un sous-domaine, selon la configuration. **À vérifier sur la version Pro retenue.**

## Contexte

Un dépôt Docker hébergé doit être joignable à la racine de son propre hôte, car les clients Docker (`docker login`, `docker pull`, `docker push`) n'acceptent pas un préfixe de chemin. Le §3.3 de la spec laisse trois options ouvertes et demande de trancher en conception détaillée. Les démos de `nexusus.md` supposent déjà des hôtes distincts par dépôt et par groupe.

## Options

| Option | Principe | Avantages | Inconvénients |
|---|---|---|---|
| **A. Sous-domaine par dépôt** | `docker-candidat.<domaine>`, `docker-release.<domaine>`, `docker-proxy-public.<domaine>`, `docker-all.<domaine>` | Compatible avec les clients Docker, pas de port à gérer, certificat wildcard unique, cohérent avec le §3.3 | Nécessite un DNS wildcard et un certificat wildcard |
| B. Port dédié par dépôt | `<hôte>:5001`, `<hôte>:5002`, … | Pas de DNS à ajouter | Un port par dépôt et par groupe, ports à ouvrir et à documenter, pare-feu plus complexe |
| C. Chemin | `<hôte>/docker-candidat/` | Un seul hôte | Non compatible avec le protocole de registre à la racine ; écarté |

## Décision

**Option A** : un sous-domaine par dépôt Docker et par groupe Docker, terminé sur le répartiteur de charge, en TLS (spec §5.3).

- Les noms suivent la forme `<nom-du-dépôt>.<domaine-interne>`, où le nom du dépôt est celui de la matrice §3.1.
- Un DNS wildcard `*.<domaine-interne>` et un certificat wildcard sont utilisés pour éviter une modification par dépôt.
- La règle de chemin de la §4 s'applique à l'intérieur de chaque dépôt : `service.hra/…`.

## Conséquences

- Les démos de `nexusus.md` (S1, S6, S11) sont valables telles quelles, à condition de remplacer `<hôte>` par le domaine réel.
- Le client Docker doit faire confiance à l'autorité de certification interne (sans quoi `docker login` échoue en TLS).
- Ajouter un dépôt Docker ou un groupe demande une entrée DNS (couverte par le wildcard) et une configuration du répartiteur (routage par nom d'hôte).
- Le répartiteur doit router par nom d'hôte vers le bon dépôt : à décrire dans le runbook (S9).

## Choix retenus (15/10/2026)

1. **Domaine** : domaine interne (`<domaine-interne>`, suffixe DNS à renseigner dans le runbook).
2. **Certificat** : autorité interne. Les clients Docker doivent faire confiance à cette autorité.
3. **Répartiteur** : Caddy est hors périmètre de cet ADR. Le choix du répartiteur ne fait pas partie de cette décision.

## Point restant avant acceptation

- **Vérification Nexus Pro** : confirmer que le routage par nom d'hôte est pris en charge sur la version retenue, et noter la procédure exacte dans le runbook.
