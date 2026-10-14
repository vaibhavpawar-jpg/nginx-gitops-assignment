# ADR 0001: Use Argo CD and Helm for GitOps deployment
- Status: Accepted
- Date: 2026-10-13

## Context
The assignment requires repeatable deployment, scaling, rolling updates, and rollback in a local Kind cluster.

## Decision
Use a Helm chart for Deployment and Service resources, and an Argo CD Application to reconcile that chart from Git. Git is the durable source of truth. Use locally loaded image tags for the laptop exercise.

## Consequences
- Replica count, image tag, and rollout settings are configurable through Git.
- Argo CD detects drift and can automatically synchronize changes.
- Local images must be reloaded if the Kind cluster is recreated.
- Shared or production environments should use a registry and immutable image tags.
