#!/usr/bin/env bash
set -euo pipefail
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "Waiting for Argo CD server to become Available..."
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s
echo "Argo CD server is available. Start UI access with: kubectl port-forward svc/argocd-server -n argocd 8080:443"
