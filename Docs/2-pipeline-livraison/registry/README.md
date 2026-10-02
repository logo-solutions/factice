# Registry : Nexus et gouvernance

Cette section documente la gouvernance des artefacts Docker avec Nexus Repository 3 Community.

Concepts clés :
- **Immuabilité** : une fois en release, l'image ne change plus
- **Promotion** : republication contrôlée de candidat vers release
- **Empreinte** : référence unique et permanente (digest SHA256)
- **SBOM** : Software Bill of Materials — composition de l'image

Documents :
- [nexus-architecture.md](nexus-architecture.md) — Décisions, dépôts, promotion
- [nexus-spec.md](nexus-spec.md) — Spécification technique et mise en œuvre
- [nexus-presentation.md](nexus-presentation.md) — Présentation pour stakeholders
