# Step-by-step guide (macOS + Kind)
Run commands from the repository root unless stated otherwise.

## 0. Check prerequisites and cluster
```bash
docker version
kind get clusters
kubectl config current-context
kubectl get nodes
helm version
```
Expected: Docker responds, your Kind cluster is listed, `kubectl` uses the correct Kind context, nodes are `Ready`, and Helm prints its version. If your cluster is not named `kind`, set `export KIND_CLUSTER_NAME=your-cluster-name` before running the image script.

## 1. Create and push a Git repository
Create an empty remote repository on GitHub (or your Git host). Then run:
```bash
git init
git branch -M main
git add .
git commit -m "Add NGINX Helm and Argo CD GitOps project"
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/nginx-gitops-assignment.git
git push -u origin main
```
Replace the example remote URL with your own. `git status` should report a clean working tree. For a private repo, configure repository credentials in Argo CD; never commit a token.

## 2. Build both versions and load them into Kind
```bash
chmod +x scripts/*.sh
./scripts/build-and-load-images.sh
docker images nginx-assignment
```
`docker build` packages the selected page into an NGINX image. `kind load docker-image` copies each image into the Kind node(s). Expected: `nginx-assignment:v1` and `nginx-assignment:v2` appear in the image list.

Optional test before Kubernetes:
```bash
docker run --rm -d --name nginx-v1-test -p 8081:80 nginx-assignment:v1
curl -s http://localhost:8081 | grep 'NGINX Application'
docker rm -f nginx-v1-test
docker run --rm -d --name nginx-v2-test -p 8082:80 nginx-assignment:v2
curl -s http://localhost:8082 | grep 'NGINX Application'
docker rm -f nginx-v2-test
```
Expected: Version 1 appears for port 8081 and Version 2 for port 8082.

## 3. Validate Helm before deployment
```bash
helm lint charts/nginx-app
helm template nginx-app charts/nginx-app
```
`lint` checks chart structure; `template` renders YAML locally without installing it. Expected: lint succeeds, and the rendered Deployment has 2 replicas, RollingUpdate, `maxSurge: 1`, `maxUnavailable: 0`, plus a Service.

## 4. Install Argo CD
```bash
./scripts/install-argocd.sh
kubectl get pods -n argocd
```
Expected: Argo CD components become Running/Ready. Start the UI port-forward in one terminal:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Open `https://localhost:8080`. In a second terminal, get the initial admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
Login as `admin`; change the password after first login. Keep it secret and do not commit it.

## 5. Configure the Argo CD Application
Edit `argocd/application.yaml` and replace `https://github.com/YOUR_GITHUB_USERNAME/nginx-gitops-assignment.git` with your real repository URL. Then commit and push:
```bash
git add argocd/application.yaml
git commit -m "Configure Argo CD repository URL"
git push
```
Create the Application:
```bash
kubectl apply -f argocd/application.yaml
kubectl get applications -n argocd
kubectl get pods -n nginx-app
```
Expected: Application `nginx-app` becomes Synced/Healthy and two Pods become Running/Ready. If the repo is private, set up repo credentials first.

## 6. Verify Version 1 in the browser
```bash
kubectl port-forward -n nginx-app svc/nginx-app 8080:80
```
Open `http://localhost:8080`. Expected heading: `NGINX Application — Version 1`. In another terminal:
```bash
kubectl get deployment,replicaset,pods,service -n nginx-app
kubectl describe deployment nginx-app -n nginx-app
kubectl get endpoints nginx-app -n nginx-app
```
Expected initially: desired/current/available replicas are 2; one ReplicaSet owns two Pods; the Service has endpoints for ready Pods.

## 7. Scale 2 → 5 → 2 and delete a Pod
For a manual experiment:
```bash
kubectl scale deployment/nginx-app -n nginx-app --replicas=5
kubectl rollout status deployment/nginx-app -n nginx-app
kubectl get pods -n nginx-app -o wide
kubectl get rs -n nginx-app
kubectl scale deployment/nginx-app -n nginx-app --replicas=2
kubectl get pods -n nginx-app
```
Expected: five Pods after scaling up and two after scaling down. Since the Pod template did not change, the same ReplicaSet usually manages them. Because Argo CD self-healing is enabled, it can restore the Git-declared replica count; for a persistent GitOps scaling demo, change `replicaCount` in `values.yaml`, commit and push.

Delete one Pod to observe replacement:
```bash
kubectl get pods -n nginx-app
kubectl delete pod ACTUAL_POD_NAME -n nginx-app
kubectl get pods -n nginx-app -w
```
Replace `ACTUAL_POD_NAME` with a real Pod name. Expected: the ReplicaSet creates a replacement and the desired replica count returns.

## 8. Upgrade Version 1 → Version 2
Edit `charts/nginx-app/values.yaml` to set `image.tag: v2`. Commit and push:
```bash
git add charts/nginx-app/values.yaml
git commit -m "Deploy NGINX Version 2"
git push
```
Watch the rollout:
```bash
kubectl rollout status deployment/nginx-app -n nginx-app
kubectl get deployment,rs,pods -n nginx-app -w
```
In another terminal, if the Service port-forward is running:
```bash
while true; do curl -s http://localhost:8080 | grep -o 'NGINX Application — Version [12]'; sleep 1; done
```
Stop with Ctrl+C. Requests may return either version during the rollout because ready Pods from both ReplicaSets can match the same Service selector. Final state should be two ready Version 2 Pods and the old ReplicaSet scaled to zero.

## 9. Three maxSurge/maxUnavailable experiments
Use 4 replicas and perform a rollout for each combination by changing the image tag v1↔v2 in Git. For each configuration, set `replicaCount: 4`, update `rollingUpdate`, commit/push, and watch:
```bash
kubectl rollout status deployment/nginx-app -n nginx-app
kubectl get deployment nginx-app -n nginx-app
kubectl get pods -n nginx-app
kubectl get rs -n nginx-app
kubectl describe deployment nginx-app -n nginx-app
```
| Config | Replicas | maxSurge | maxUnavailable | Theoretical max Pods |
|---|---:|---:|---:|---:|
| 1 | 4 | 1 | 0 | 5 |
| 2 | 4 | 2 | 1 | 6 |
| 3 | 4 | 0 | 1 | 4 |

Maximum possible Pod count is replicas + maxSurge. The actual observed maximum can be lower depending on timing, readiness, and scheduling. Record what you actually observe; don't present theoretical values as measurements.

## 10. Roll back to Version 1
Recommended GitOps rollback: set `image.tag: v1` in `values.yaml`, commit and push, then run:
```bash
kubectl rollout status deployment/nginx-app -n nginx-app
kubectl get deployment,rs,pods -n nginx-app
curl -s http://localhost:8080 | grep 'NGINX Application'
kubectl rollout history deployment/nginx-app -n nginx-app
```
Expected: Version 1 serves traffic again. The Version 2 ReplicaSet usually remains with zero replicas while its revision history is retained. For a Kubernetes-only experiment, `kubectl rollout undo deployment/nginx-app -n nginx-app` uses a previous Deployment revision, but Argo CD self-healing may revert it to Git's declared version.

## 11. Evidence checklist
Capture actual screenshots for: Version 1 webpage; Deployment/Pods/Service; 2→5→2 scaling; Pod replacement; Version 2 webpage; rollout with old/new ReplicaSets; each of three rollout configurations; rollback to Version 1; Argo CD Application Synced/Healthy.

Useful evidence commands:
```bash
kubectl get deployment,rs,pods,svc -n nginx-app -o wide
kubectl describe deployment nginx-app -n nginx-app
kubectl rollout history deployment/nginx-app -n nginx-app
helm get values nginx-app -n nginx-app
```

## Troubleshooting
- `ImagePullBackOff`: ensure both images were loaded into the correct Kind cluster and `imagePullPolicy` is `IfNotPresent`.
- Argo CD repository error: verify URL, branch `main`, chart path `charts/nginx-app`, and private repo credentials.
- App not reachable: keep the port-forward process running and inspect `kubectl get endpoints -n nginx-app`.
- Manual changes revert: Argo CD self-healing is restoring Git state; edit Git instead.
