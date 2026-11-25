NAME                             READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
pod/foundation-bbdf85ff7-pf4zd   1/1     Running   0          34m   10.244.0.7   minikube   <none>           <none>

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE   SELECTOR
service/foundation   ClusterIP   10.110.179.219   <none>        8080/TCP   34m   app=foundation

NAME                                              ADDRESSTYPE   PORTS   ENDPOINTS    AGE
endpointslice.discovery.k8s.io/foundation-nt6ln   IPv4          8080    10.244.0.7   34m

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
