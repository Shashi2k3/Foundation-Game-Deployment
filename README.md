# Project 1 handover README (Shashi, individual)

Status key: executed locally (date) / pending / unavailable on BP. All deployment evidence: executed locally 2026-11-25.

Reproducible deployment of the supplied foundation page and board API (release `foundation-observe-a`) to a local
minikube cluster through GitHub pull requests, a GitHub Actions gate (`p1-gates`) and Argo CD. This minikube run
replaces the unavailable classroom cluster; BP Yalla steps remain pending. Step-by-step notes: `evidence-log.md`.

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
* Local image ID: `99bc55a3d319ddf0c8b28879090c96cd2592c874c28e146aa00594332016a823`
* Loaded into minikube with `podman save` + `minikube image load`. Pod `imageID` = `sha256:99bc55a3d319…a823` for every
  Pod in this run (blue and green): the image never changed, only configuration.

## Public configuration
* `LAB_ENV`: final intended value **`workshop-green`** (runtime.env and ConfigMap agree). It was `workshop-blue` for the
  first deploy, the controlled failure and the recovery.
* `academy/config-revision`: `"2"` (bumped from `"1"` with the green change so a new Pod starts).
* `client.json`: `deadlineMs 450, retries 0` (budget 450 x 1 = 450 <= 650).
  Historical W1.10 baseline (office laptop, emulated client, 2026-11-23): with the starting 80/0, Slow was unavailable
  after 81 ms while the server finished in 304 ms with `result_status 200` and `caller_aborted: true`
  (request `5d3e6e48-80ce-4841-9368-38a503700048`). Justification of 450/0: pending completion of W1.10 Tasks 3-5.
* `LAB_SESSION`: `p1-shashi-minikube`. `LOCAL_LOKI_URL`: empty (no Loki/Grafana in this run).

## Routing, Service and probes
* Same origin: the page calls the relative path `/api/boards/reference`, so one image and one Service serve page and API
  (no CORS, no separate API host, no cluster-internal hostname in the browser).
* Path: browser -> `kubectl port-forward` 127.0.0.1:18081 -> Service `foundation` (selector `app: foundation`,
  port 8080 -> named container port `http`) -> selected Pod -> page/API. Records go separately to Pod stdout.
  The port-forward tunnels through the Kubernetes API server; it is not a public ingress.
* `imagePullPolicy: Never`: the image is loaded into the node locally (not a BP registry policy).
* Readiness/liveness probes call `/healthz`, which only proves the process answers that route.

## Deployment revisions and review
Every change went through a GitHub PR with a self-review comment; `p1-gates` (image build + smoke) passed on each PR
before merge. CI never deploys: each deployment is `argocd --core app sync p1-foundation --revision <full SHA>`.

| PR | Change | Synced revision | Result |
|---|---|---|---|
| #1 | Initial deploy (Argo Application) | `e2ef3e9e86c9c95cd93727bb3966da7118d51d88` | Synced, Healthy, blue |
| #3 | Controlled failure: selector `app: foundation-missing` | `a807243df2718ef033435efd12fbba0ecf7d9156` | Synced, Healthy, but no endpoints |
| #4 | First recovery attempt | `0ee27e963d492a3c8e2fa2099e626b35d26cd107` | Did not fix: selector unchanged (see below) |
| #5 | Recovery: selector restored | `66e3047e262294eb7e69d8d0821e69092e35a45c` | Synced, Healthy, endpoint restored |
| #7 | Blue -> green (first attempt) | `4cab5deffd340e481b146fdf55aeeb32c798b1ea` | OutOfSync: broken resources.yaml (see below) |
| #8 | Blue -> green (fixed) | `7eef9320709306daf72a866277263c5e7ce4d315` | Synced, Healthy, new Pod, green |

Evidence-only PRs: #2 (M4), #6 (M5 recovery), #9 (green). An earlier README edit was committed directly on GitHub;
this final README went through a PR.

## Startup and verification
| Check | Command | Expected | Actual (time UTC, request ID) | Evidence |
|---|---|---|---|---|
| Local smoke | `bash smoke.sh http://127.0.0.1:18080 workshop-blue` | all 8 PASS | SMOKE PASSED | evidence/m2-local-smoke.txt |
| Local browser | page :18080, Load board Reference | 200, 3x3, 6 moves | `e2a310e2-0597-4287-8d40-ce7840988d42` matched in container log, 10:26:29 | evidence/m2-local-logs.txt |
| Pod / endpoint (blue) | `kubectl get deployment,pods,service,endpointslices` | endpoint = Pod IP | Pod `foundation-bbdf85ff7-pf4zd`, endpoint `10.244.0.7` | evidence/m4/resources.txt |
| Deployed smoke (blue) | `bash smoke.sh http://127.0.0.1:18081 workshop-blue` | all 8 PASS | SMOKE PASSED, `smoke-20261125T114506Z` | evidence/m4/smoke.txt |
| Deployed browser (blue) | page :18081, Load board Reference | received 200 board, blue | `4aec7af3-e094-4c6f-b6dd-aa70b9799886`, same ID in Pod log | evidence/m4/browser-request-record.txt |
| After recovery | smoke + browser via fresh port-forward | all PASS, blue | SMOKE PASSED `smoke-20261125T121850Z`; browser `57d0c235-eda6-4a9c-a7ce-51eba1b5355d`, 12:21:12 | evidence/m5-fixed/ |
| Pod / endpoint (green) | `kubectl get pods,endpointslices` | new Pod, endpoint = its IP | Pod `foundation-5dc7bf6db4-pcgt6`, endpoint `10.244.0.8` | evidence/m5-green/resources.txt |
| Deployed smoke (green) | `bash smoke.sh http://127.0.0.1:18081 workshop-green` | all 8 PASS, green | SMOKE PASSED | evidence/m5-green/smoke.txt |
| Deployed browser (green) | page :18081, Load board Reference | received 200 board, green | `b3a50cf7-9c66-45ef-a4c5-b981e48b6886`, 12:41:54, `workshop-green` in Pod log | evidence/m5-green/browser-request-record.txt |
| Grafana | — | matching row | not executed: Loki/Grafana not set up (Pod stdout is not a Grafana observation) | pending |

## Controlled failure and recovery
* **Prediction** (written before the change, evidence-log.md): Pod stays Running and Argo Healthy, but the Service
  selects no Pod, so endpoints empty and a new port-forward fails; rebuilding the image would not help.
* **Observed** (PR #3, `a807243`, 12:02): Argo Synced + Healthy (Deployment unchanged, Service configured); Pod
  `foundation-bbdf85ff7-pf4zd` 1/1 Running, 0 restarts; Service selector `app=foundation-missing`; EndpointSlice
  `<unset>`; fresh port-forward: `error: timed out waiting for the condition`. Prediction confirmed. CI also passed,
  because it tests the container alone, not the Service selector. Evidence: evidence/m5-fail/.
* **First recovery attempt failed** (PR #4, `0ee27e9`): `git revert` did not apply (blocked by an uncommitted
  evidence-log change), so the commit held only evidence; fresh checks still showed `foundation-missing`, empty endpoints
  and a timed-out port-forward. Preserved in evidence/m5-fix-attempt1/. Lesson: verify the corrective diff and re-check
  endpoints after sync.
* **Recovery** (PR #5, `66e3047`): only the selector restored to `app: foundation`; endpoint `10.244.0.7` back;
  fresh port-forward, smoke and browser request passed. Evidence: evidence/m5-fixed/.
* **Rejected repair:** rebuilding the image. Image and Pod were healthy throughout; the Service's label query matched nothing.

## Environment change blue -> green
* **Prediction:** bumping `academy/config-revision` with the `LAB_ENV` change alters the Pod template, so a new Pod
  starts and reads green; a ConfigMap edit alone would leave the running process on blue. Image unchanged.
* **Incident** (PR #7, `4cab5de`): a pasted command joined two lines, so `tee` overwrote resources.yaml (and smoke.sh,
  evidence-log.md) with kubectl output. CI passed (it does not validate Kubernetes config). Argo found no resources and
  showed OutOfSync `ignored (requires pruning)`; prune is disabled, so nothing was deleted and the blue Pod kept serving.
  Evidence: evidence/m5-green/incident-argo-outofsync.txt.
* **Fix** (PR #8, `7eef932`): resources.yaml restored from history with only the green change, validated with
  `kubectl apply --dry-run=server` before review. Sync replaced `foundation-bbdf85ff7-pf4zd` with
  `foundation-5dc7bf6db4-pcgt6`; same image ID; fresh smoke and browser request report `workshop-green`. Prediction confirmed.

## Recovery procedure
* Re-sync the last known-good reviewed revision (`argocd --core app sync p1-foundation --revision 7eef9320709306daf72a866277263c5e7ce4d315`),
  or revert the faulty PR with a new reviewed PR; verify the diff, sync, confirm the endpoint equals the Pod IP, start a
  fresh port-forward and repeat the verification table.
* If ConfigMap values change, update runtime.env and bump `academy/config-revision` in the same commit.

## Lessons and possible improvement
* Argo "Healthy" and a green CI check did not prove the app was reachable: endpoint and request checks were needed.
* CI could also validate `configuration/app/resources.yaml` (e.g. a Kubernetes dry-run or schema check) to catch the
  PR #7 incident before merge. Not implemented in this run.

