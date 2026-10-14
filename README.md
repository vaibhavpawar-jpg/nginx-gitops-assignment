# NGINX GitOps Assignment — Kind + Helm + Argo CD

A hands-on learning project for Deployments, ReplicaSets, scaling, RollingUpdate, `maxSurge`, `maxUnavailable`, and rollback.

## Prerequisites
macOS, Docker Desktop running, an existing Kind cluster, and `git`, `docker`, `kind`, `kubectl`, and `helm` installed.

## Quick start
1. Read [`docs/STEP_BY_STEP.md`](docs/STEP_BY_STEP.md).
2. Build and load both local images: `./scripts/build-and-load-images.sh`.
3. Install Argo CD: `./scripts/install-argocd.sh`.
4. Replace the example Git URL in `argocd/application.yaml` with your actual repository URL, commit, and push.
5. Apply the Argo CD Application: `kubectl apply -f argocd/application.yaml`.
6. Access the app: `kubectl port-forward -n nginx-app svc/nginx-app 8080:80`, then open `http://localhost:8080`.

## Kind image note
Kind nodes do not automatically use images from your Mac's Docker image store. Build and load `nginx-assignment:v1` and `nginx-assignment:v2` into the correct Kind cluster. For shared/production clusters, use a container registry and immutable tags.

## GitOps note
Argo CD is configured for automated sync and self-healing. Permanent changes should be made in Git. Manual `kubectl scale` and `kubectl rollout undo` are useful experiments, but Argo CD may reconcile them back to the version declared in Git.
