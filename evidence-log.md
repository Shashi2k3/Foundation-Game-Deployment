# Project 1 evidence log

| Time (UTC) | Milestone | Operator / predictor | Observation (command, result, identifiers) | Evidence file |
|---|---|---|---|---|
| | 1 baseline | | | |
| | 2 local image ID | | | local-headers.txt, local-board.json |
| | 3 review decision | | | |
| | 4 Argo revision / Pod image / endpoint / response / Grafana row | | | ../running-pods.json |
| | 5 failure + recovery | | | |
| | 6 peer reproduction | | | |

Individual reflection (each learner): assistance used, one next learning step.

## Milestone 5 prediction (written before the change)
* Known-good revision: e2ef3e9e86c9c95cd93727bb3966da7118d51d88 (PR #1), evidence in evidence/m4/.
* Change: only the Service selector app: foundation -> app: foundation-missing.
* Prediction: the Pod stays 1/1 Running and Argo stays Healthy, because the Deployment and Pod are unchanged.
  The Service now selects no Pod (no Pod has label app=foundation-missing), so its endpoints become empty
  and a NEW port-forward to the Service fails. Rebuilding the image would not help: the image was never the fault,
  the Service's label query is.

## Milestone 5 observed failure (2026-11-25 12:02 UTC)
* Bad revision a807243df2718ef033435efd12fbba0ecf7d9156 synced: Argo Synced + Healthy; Deployment unchanged, Service configured.
* Pod foundation-bbdf85ff7-pf4zd still 1/1 Running (0 restarts); Service selector app=foundation-missing;
  EndpointSlice endpoints <unset>; fresh port-forward: "error: timed out waiting for the condition".
* Prediction confirmed. Argo "Healthy" did not mean reachable: endpoint and request checks were needed.
  CI (p1-gates) also passed on this PR, because it tests the container alone, not the Service selector.
* Rejected repair: rebuilding the image. The image and Pod were fine; the Service's label query matched nothing.
