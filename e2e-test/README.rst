e2e test result
===============

Run horizontal autoscaling tests::

 $ go run hack/e2e.go -- --provider=skeleton -v --test --test_args="--ginkgo.focus=Horizontal"

The feature is described on https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
With this feature, k8s automatically scale the number of pods based on observed CPU utilization.

