# CI/CD : Build et promotion

Cette section décrit le workflow CI/CD (`.github/workflows/ci.yml`) en quatre étapes :

1. **build** — Tests et construction (tous les pushs)
2. **promote** — Contrôles et promotion en release (push sur main)
3. **deploy-integration** — Déploiement automatique
4. **deploy-production** — Déploiement manuel (décision humaine)

Documents :
- [pipeline-build-promotion.md](pipeline-build-promotion.md) — déroulé, dépendances, retour arrière, écarts connus
- [securite-pipeline.md](securite-pipeline.md) — durcissement, analyse, signature : état, écart, cible
