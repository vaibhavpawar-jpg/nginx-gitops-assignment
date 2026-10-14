# Agent Instructions

## Goal
Maintain the NGINX Version 1/Version 2 learning application deployed to Kind through Helm and Argo CD.

## Source of truth
- Git is the durable source of truth for desired Kubernetes state.
- `charts/nginx-app/values.yaml` controls replica count, image tag, and rollout policy.
- `argocd/application.yaml` defines the Argo CD Application.
- Prefer editing Git and allowing Argo CD to sync over permanent manual `kubectl` edits.

## Layout and conventions
- Versioned pages: `app/v1/index.html`, `app/v2/index.html`.
- Container build: `app/Dockerfile`.
- Helm chart: `charts/nginx-app/`.
- Architecture decisions: `docs/ADR/`.
- Walkthrough and report: `docs/STEP_BY_STEP.md`, `docs/REPORT_TEMPLATE.md`.

## Validation and safety
- Check `git status` and review diffs before committing.
- Run `helm lint charts/nginx-app` and `helm template nginx-app charts/nginx-app`.
- Never commit credentials, kubeconfigs, tokens, or private keys.
- After deployment, check `kubectl rollout status`, Pods, ReplicaSets, and Events.
- Report actual command output; never claim tests passed unless run.
