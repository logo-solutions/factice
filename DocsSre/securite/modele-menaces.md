# Modèle de menaces

Analyse STRIDE des flux décrits dans [flux-et-reseau.md](flux-et-reseau.md), aux frontières de confiance de [zones-securite.md](zones-securite.md). Elle sert à décider **où concentrer les mesures**, pas à être exhaustive.

## Méthode

1. Découper le système en éléments et flux (diagramme de flux de données).
2. Repérer les frontières de confiance.
3. Pour chaque flux qui franchit une frontière, examiner les six catégories STRIDE : usurpation (**S**poofing), altération (**T**ampering), répudiation (**R**epudiation), divulgation d'information (**I**nformation disclosure), déni de service (**D**enial of service), élévation de privilèges (**E**levation of privilege).
4. Noter la mesure actuelle, l'écart et la priorité.

## Menaces par frontière

### Développeur vers GitHub, puis GitHub vers runner

| Cat. | Menace | Mesure actuelle | Écart | Priorité |
|---|---|---|---|---|
| S | usurpation d'un compte qui fusionne ou lance la production | authentification GitHub | authentification forte et relecteurs obligatoires non décrits dans le dépôt | haute |
| T | modification du workflow pour exfiltrer des secrets ou déployer | revue de la demande de fusion | pas de règle de dépôt documentée, pas d'analyse des workflows | haute |
| T | code malveillant exécuté par une demande de fusion sur le runner | secrets exclus des demandes de fusion | le runner exécute tout de même le code de la branche sur l'hôte | haute |
| R | contestation d'une mise en production | historique GitHub, événement de déploiement | le journal local d'événements est dans l'espace de travail du runner | moyenne |
| E | un jeton aux droits trop larges | aucune | pas de bloc `permissions` | haute |

### Runner vers Nexus

| Cat. | Menace | Mesure actuelle | Écart | Priorité |
|---|---|---|---|---|
| S | usage d'un compte de service volé | trois comptes aux droits distincts | mots de passe longue durée, pas de rotation datée | moyenne |
| T | remplacement d'une image dans le registre | release immuable, déploiement par empreinte, contrôle de provenance | pas de signature : qui peut écrire dans le registre peut introduire une image | haute |
| I | interception des identifiants si `NEXUS_URL` est en HTTP | aucune garantie | vérifier HTTPS ou réseau de confiance | moyenne |
| D | indisponibilité ou saturation du registre | aucune | les limites de la version communautaire sont suivies dans le sujet registre | basse |

### Runner et Ansible vers l'hôte

| Cat. | Menace | Mesure actuelle | Écart | Priorité |
|---|---|---|---|---|
| E | un job compromis agit avec les droits du compte du runner sur toute la machine, bases de production comprises | aucune frontière | runner dédié, éphémère ou sur un autre hôte | haute |
| I | lecture des secrets de l'hôte (fichier de clé du coffre, fichiers `.env`) | modes `0600` | `vault.yml` non chiffré ; mots de passe visibles dans la ligne de commande de la création de l'utilisateur de base | haute |
| T | modification d'un playbook ou d'un rôle | revue de la demande de fusion | pas d'analyse statique | moyenne |

### Client vers Caddy, puis tiers

| Cat. | Menace | Mesure actuelle | Écart | Priorité |
|---|---|---|---|---|
| I | écoute du trafic | aucune | pas de TLS | selon l'exposition |
| S | usurpation de l'origine d'une requête | aucune | aucune authentification décrite côté client | selon l'usage |
| T | accès direct au conteneur App, en contournant Caddy | aucune | port publié sur toutes les interfaces | haute |
| D | saturation de l'application | aucune limitation de débit | à étudier | basse |
| E | l'application modifie le schéma de la base | aucune | l'utilisateur applicatif est propriétaire de la base | moyenne |
| I | secrets dans les journaux d'Ansible | `no_log` sur une tâche | à généraliser | moyenne |

## Hypothèses

- La maquette n'est pas exposée sur Internet.
- Les contributeurs au dépôt sont des personnes de confiance ; la protection vise l'erreur et le compte compromis, pas un contributeur hostile permanent.
- Si ces hypothèses changent (exposition publique, contributeurs externes), plusieurs priorités passent en haute.

## Mesures prioritaires

| Rang | Mesure | Document |
|---|---|---|
| 1 | Droits minimaux du jeton, relecteurs obligatoires sur `production`, règles de dépôt | [securite-pipeline.md](../2-pipeline-livraison/ci-cd/securite-pipeline.md) |
| 2 | Lier les ports aux interfaces locales ; pare-feu versionné | [isolation-et-reseau.md](../4-securite/isolation-et-reseau.md) |
| 3 | Chiffrer ou externaliser les secrets | [bonnes-pratiques-ansible.md](../2-pipeline-livraison/orchestration/bonnes-pratiques-ansible.md) |
| 4 | Signer les images et vérifier au déploiement | [securite-pipeline.md](../2-pipeline-livraison/ci-cd/securite-pipeline.md) |
| 5 | Séparer ou rendre éphémère le runner | [securite-pipeline.md](../2-pipeline-livraison/ci-cd/securite-pipeline.md) |

## Entretien du modèle

Le revoir à chaque changement d'architecture (nouveau flux, nouvel hôte, nouvelle exposition) et après tout incident. Les menaces non traitées doivent figurer ici avec une décision d'acceptation datée.

## Références

- OWASP, [Threat Modeling Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html)
- Microsoft, [méthode STRIDE](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats)
- NIST, [SP 800-207 Zero Trust Architecture](https://csrc.nist.gov/pubs/sp/800/207/final)
- OWASP, [Top 10 CI/CD Security Risks](https://owasp.org/projects/top-10-cicd-security-risks)
