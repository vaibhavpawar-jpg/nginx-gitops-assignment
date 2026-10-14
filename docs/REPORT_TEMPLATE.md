# Assignment Report: NGINX Deployment, Scaling and Rolling Updates

## Environment
- macOS version:
- Kind cluster name:
- Kubernetes version:
- Helm version:
- Argo CD version:
- Git repository URL:

## Evidence
List screenshot filenames and what each proves.

## Observations
- Initial desired/current/available replicas:
- After scaling 2 → 5:
- After scaling back to 2:
- Pod deletion and replacement observed:
- Version 1 ReplicaSet:
- Version 2 ReplicaSet:
- Maximum Pod count observed for each rollout configuration:
- Final version after rollback:

## Answers
1. **Deployment vs ReplicaSet:** A Deployment manages ReplicaSets and rollout history; a ReplicaSet maintains the requested number of matching Pods.
2. **How desired replicas are maintained:** Controllers continuously reconcile actual state with desired state. A ReplicaSet creates replacement Pods when the count is too low.
3. **When a Pod is deleted:** Its ReplicaSet creates a replacement Pod with a new name.
4. **RollingUpdate:** Kubernetes gradually scales up the new ReplicaSet and scales down the old ReplicaSet according to availability and surge limits.
5. **maxSurge:** Maximum extra Pods allowed above desired replicas during a rollout; can be an integer or percentage.
6. **maxUnavailable:** Maximum desired replicas allowed to be unavailable during the rollout; can be an integer or percentage.
7. **Multiple ReplicaSets:** Different Deployment Pod templates create different ReplicaSet revisions, supporting rollout history and rollback.
8. **Can both versions receive traffic?** Yes, potentially. The Service selects Pods by labels, not by image version. Ready Pods from both ReplicaSets can match during a rollout.
9. **Rollback:** Kubernetes can restore a retained Deployment revision. With GitOps, changing the Git image tag back is the durable rollback because Argo CD reconciles Git state.
10. **Production recommendation:** RollingUpdate with readiness probes and conservative availability settings (for example, `maxUnavailable: 0` and a small `maxSurge` if capacity permits), plus resource requests/limits, monitoring, and testing.

## Experiment table
| Configuration | Replicas | maxSurge | maxUnavailable | Maximum Pods observed | Rollout behavior / evidence |
|---|---:|---:|---:|---:|---|
| 1 | 4 | 1 | 0 | | |
| 2 | 4 | 2 | 1 | | |
| 3 | 4 | 0 | 1 | | |

## Resource relationship
Deployment → ReplicaSet → Pod → Container:
- Deployment manages ReplicaSets and revisions.
- ReplicaSet maintains the number of Pods.
- Pod is the scheduling unit and contains one or more containers.
- Container runs the NGINX image and serves the HTML page.
