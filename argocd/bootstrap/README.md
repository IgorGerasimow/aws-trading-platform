# Argo CD Bootstrap
- Create `argocd` namespace and install Argo CD (operator or upstream manifests).
- Apply `argocd/applications/app-of-apps.yaml` with template filled for each region (set `path`).
- Or deploy per-app Application manifests in `k8s/regions/<region>/apps/`.
