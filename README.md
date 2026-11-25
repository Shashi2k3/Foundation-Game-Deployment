# Project 1 handover README (Shashi, individual)

Status key: executed locally (date) / pending / unavailable on BP.

Reproducible deployment of the supplied foundation page and board API (release `foundation-observe-a`) to a local
minikube cluster through GitHub pull requests, a GitHub Actions gate (`p1-gates`) and Argo CD. This minikube run
replaces the unavailable classroom cluster; BP Yalla steps remain pending.

## Starting files and source version
* Supplied application copied unchanged from `w1-project/code/app` (release `foundation-observe-a`), except
  `app/wwwroot/client.json`, replaced by the guided `{"deadlineMs":450,"retries":0}`.
* First source commit: `46d0be7` (merged with the GitHub initial commit as `89638be`).
* Files I own: `app/wwwroot/client.json`, `runtime.env`, `Containerfile`, `configuration/app/resources.yaml`,
  `argocd/application.yaml`, `smoke.sh`, `.github/workflows/p1-gates.yml`.

## Prerequisites
* Windows + WSL Ubuntu 26.04 (x86_64), Podman 5.7.0, Git, GitHub CLI, kubectl, minikube v1.39.0 (Podman driver,
  containerd 2.3.4, Kubernetes v1.37.0), Argo CD v3.5.2 core install. No local .NET SDK (the image build compiles the app).
* Public GitHub repo: https://github.com/Shashi2k3/Foundation-Game-Deployment (no secrets; kubeconfig and tokens stay outside).

## Build and image identity
* Build: `podman build -f Containerfile -t localhost/p1-foundation:foundation-a .`
* Containerfile change from the guided recipe: a build stage (`dotnet/sdk:10.0`) runs `dotnet publish` inside the image,
  so no host SDK is needed; the runtime stage keeps the supplied `aspnet:10.0.12` base pinned by digest, copies only the
  published output, listens on 8080 and starts `dotnet Foundation.dll`.
* Local image ID (executed locally 2026-11-25): `99bc55a3d319ddf0c8b28879090c96cd2592c874c28e146aa00594332016a823`
* Loaded into minikube with `podman save` + `minikube image load`; Pod `imageID` = `sha256:99bc55a3d319…a823` (identical).

## Public configuration
* `LAB_ENV`: `workshop-blue` (runtime.env and ConfigMap). Final intended value: ____
* `client.json`: `deadlineMs 450, retries 0` (budget 450 x 1 = 450 <= 650). Justification from W1.10 evidence: ____
* `LAB_SESSION`: `p1-shashi-minikube`. `LOCAL_LOKI_URL`: empty (no Loki/Grafana in this run).

## Routing, Service and probes
* Same origin: the page calls the relative path `/api/boards/reference`, so one image and one Service serve page and API
  (no CORS, no separate API host, no cluster-internal hostname in the browser).
* Path: browser -> `kubectl port-forward` 127.0.0.1:18081 -> Service `foundation` (selector `app: foundation`,
  port 8080 -> named container port `http`) -> selected Pod -> page/API. Records go separately to Pod stdout.
  The port-forward tunnels through the Kubernetes API server; it is not a public ingress.
* `imagePullPolicy: Never`: the image is loaded into the node locally (not a BP registry policy).
* Readiness/liveness probes call `/healthz`, which only proves the process answers that route.

## Deployment revision and review
* Initial deploy: PR #1, revision `e2ef3e9e86c9c95cd93727bb3966da7118d51d88`, self-review comment on the PR,
  p1-gates passed before merge. `argocd --core app sync p1-foundation --revision e2ef3e9…`: Synced, Healthy (2026-11-25 11:40 UTC).

## Startup and verification (executed locally 2026-11-25)
| Check | Command | Expected | Actual (time, request ID) | Evidence |
|---|---|---|---|---|
| Local smoke | `bash smoke.sh http://127.0.0.1:18080` | all 8 PASS | SMOKE PASSED | evidence/m2-local-smoke.txt |
| Local browser | page :18080, Load board Reference | 200, 3x3, 6 moves | request `e2a310e2-0597-4287-8d40-ce7840988d42` matched in container log, 10:26:29 UTC | evidence/m2-local-logs.txt |
| Pod / endpoint | `kubectl get deployment,pods,service,endpointslices` | Pod Running, endpoint = Pod IP | Pod `foundation-bbdf85ff7-pf4zd` 1/1, endpoint `10.244.0.7` | evidence/m4/resources.txt |
| Deployed smoke | `bash smoke.sh http://127.0.0.1:18081` | health, page, reference 200 3x3/6, release, env blue, ID echoed, missing 404 | SMOKE PASSED, `smoke-20261125T114506Z` | evidence/m4/smoke.txt |
| Deployed browser | page :18081, Load board Reference | received 200 board, blue | request `4aec7af3-e094-4c6f-b6dd-aa70b9799886` received; same ID in Pod log | evidence/m4/browser-request-record.txt |
| Grafana | — | matching row | not executed: Loki/Grafana not set up in this run (Pod stdout is not a Grafana observation) | pending |

## Controlled failure and recovery
* Bad revision (PR #__, `____`): Service selector `app: foundation-missing`. Prediction in evidence-log.md. Observed: ____
* Corrective revision (PR #__, `____`) and fresh verification: ____
* Environment change blue -> green (PR #__, `academy/config-revision` 1 -> 2) and header evidence: ____

## Recovery procedure
* Re-sync the last known-good reviewed revision (`argocd --core app sync p1-foundation --revision <good SHA>`), or revert
  the bad PR with a new reviewed PR; then start a fresh port-forward and repeat the verification table.

## BP items still pending
* Yalla scaffolding, BP pull request, BP registry and deployment: unavailable (approved walkthrough not supplied).
  This minikube run is local project evidence only.
* Grafana request match: pending (not set up). Peer reproduction: pending.
