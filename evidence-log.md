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

## Milestone 5 first recovery attempt (2026-11-25 12:09 UTC): failed, preserved
* Corrective revision 0ee27e963d492a3c8e2fa2099e626b35d26cd107 synced, but the Service selector was still
  app=foundation-missing and endpoints <unset>: the git revert had not applied (uncommitted evidence-log.md change
  blocked it), so that commit contained only evidence. Fresh smoke failed; fresh port-forward timed out.
* Lesson: verify the corrective diff itself and re-check endpoints after sync; a "fix" commit is not proof of a fix.
* Note: the "board 3x3" PASS in that run was a false pass (stale /tmp/board.json); smoke.sh fixed below.
## Milestone 5 recovery verified (2026-11-25 12:18 UTC)
* Corrective revision (fix-selector-2) synced: Service selector app=foundation, endpoint 10.244.0.7 = Pod IP.
* Fresh port-forward worked; smoke PASSED (smoke-20261125T121850Z); browser request matched in Pod log
  (evidence/m5-fixed/browser-request-record.txt).
* smoke.sh was accidentally overwritten by command output during recovery; restored from the known script.

## Milestone 5.3 prediction: blue -> green (written before the change)
* Change LAB_ENV workshop-blue -> workshop-green in runtime.env and the ConfigMap, and bump
  academy/config-revision "1" -> "2" in the Pod template, in the same commit.
* Prediction: the annotation change alters the Pod template, so Kubernetes replaces the Pod (new name);
  the new Pod reads LAB_ENV at start, so a fresh request returns X-Lab-Environment: workshop-green.
  Board, release (foundation-observe-a), image ID and health stay the same.
  Without the annotation bump, the ConfigMap would change but the running Pod would keep workshop-blue.

## Milestone 5.3 incident (2026-11-25 12:25 UTC): broken config merged, preserved
* A pasted command joined two lines, so `tee` overwrote resources.yaml, smoke.sh and evidence-log.md with kubectl output.
* PR #7 (4cab5de) merged that resources.yaml: CI passed (it does not validate Kubernetes config); Argo found no
  resources and reported OutOfSync "ignored (requires pruning)". Prune is disabled, so nothing was deleted and the
  blue Pod kept running. Evidence: evidence/m5-green/incident-argo-outofsync.txt.
* Fix: resources.yaml restored from 0d4ea3f with only the green change applied; validated with kubectl dry-run before review.

## Milestone 5.3 result (2026-11-25 12:37 UTC): prediction confirmed
* Revision 7eef9320709306daf72a866277263c5e7ce4d315 (PR #8) synced: Synced + Healthy.
* Pod replaced: foundation-bbdf85ff7-pf4zd (blue) -> foundation-5dc7bf6db4-pcgt6 (10.244.0.8); image ID unchanged
  (sha256:99bc55a3d319...a823). Fresh smoke and browser request report workshop-green (evidence/m5-green/).
