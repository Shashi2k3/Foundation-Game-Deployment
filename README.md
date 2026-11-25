# Project 1 handover README (team: p1-team-__)

Status key: executed in classroom (date) / executed locally (date) / pending / unavailable on BP.

## Starting files and source version
* Supplied application copied from: ../code/app (unchanged) - source checksum or commit: ____
* Files we own: client.json (deadlineMs/retries), runtime.env (LAB_ENV), Containerfile, configuration/app/resources.yaml

## Prerequisites
* .NET SDK ____, Podman ____, kubectl/argocd (classroom), environment session variables (names only, no values that are secrets)

## Build and image identity
* Commands: (dotnet publish ..., podman build ..., podman image inspect ...)
* Image label / image ID (local): ____   Imported runtime image ID (facilitator report): ____

## Public configuration
* LAB_ENV: ____  client.json: ____ (justification from W1.10 evidence)

## Deployment revision and review
* Configuration commit (full): ____   Reviewer and decision: ____
* Argo revision / sync / health: ____

## Startup and verification
| Check | Command | Expected | Actual (time, request ID) |
|---|---|---|---|
| Health | curl /healthz | 200 Healthy | |
| Reference | page + /api/boards/reference | 200, 3x3, 6 moves, foundation-observe-a, env | |
| Missing | /api/boards/missing | 404 NOT_FOUND | |
| Grafana | {job="academy-w110", session="..."} \| json \| request_id="..." | matching row | |

## Controlled failure and recovery
* Bad revision / prediction / observed (healthy Pod, empty endpoints, failed port-forward):
* Corrective revision and fresh verification:
* Environment change blue -> green (annotation increment) and header evidence:

## Recovery procedure
* Restore the last reviewed configuration revision: ____ ; then repeat the verification table.

## BP items still pending
* Yalla scaffolding, BP pull request, BP deployment: pending (approved walkthrough not supplied).
