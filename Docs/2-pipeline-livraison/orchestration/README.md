# Orchestration : Ansible et déploiement

Cette section décrit comment Ansible orchestre le déploiement des trois tiers et l'application du rôle générique `deploy_stack`.

Points clés :
- **Orchestration locale** : Ansible s'exécute sur l'hôte lui-même, pas en SSH distant
- **Trois tiers** : BDD (PostgreSQL natif), App (conteneur Docker), Web (Caddy natif)
- **Idempotence** : relancer un playbook = pas de changement (sauf si config change)
- **Par empreinte** : le déploiement tire l'image depuis le digest SHA256

Documents :
- [workflow-ansible.md](workflow-ansible.md) — Flux d'exécution, contrôles de santé
- [deploy-stack-contract.md](deploy-stack-contract.md) — Contrat du rôle générique et écarts
- [bonnes-pratiques-ansible.md](bonnes-pratiques-ansible.md) — Qualité, tests, secrets, déploiement : état, écart, cible
