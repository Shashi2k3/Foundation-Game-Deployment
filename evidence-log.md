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
