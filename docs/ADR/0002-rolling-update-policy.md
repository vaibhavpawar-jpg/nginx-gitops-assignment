# ADR 0002: RollingUpdate with explicit availability settings
- Status: Accepted
- Date: 2026-10-13

## Context
The exercise must demonstrate gradual replacement of Version 1 Pods by Version 2 while the Service remains available.

## Decision
Use Deployment strategy `RollingUpdate`, initially with `maxSurge: 1` and `maxUnavailable: 0`. Test alternatives with four replicas.

## Consequences
- `maxSurge` limits extra Pods above desired replicas during a rollout.
- `maxUnavailable` limits the number of desired replicas that may be unavailable during a rollout.
- Production settings depend on capacity, readiness behavior, and disruption tolerance.
