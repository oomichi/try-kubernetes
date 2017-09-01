e2e test result
===============

The horizontal autoscaling feature is described on https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
With this feature, k8s automatically scale the number of pods based on observed CPU utilization.
As normal usage, we can set autoscaling with::

 $ kubectl autoscale rc foo --min=2 --max=5 --cpu-percent=80

for replication controller foo, with target CPU utilization set to 80% and the number of replicas between 2 and 5.

Run horizontal autoscaling tests::

 $ go run hack/e2e.go -- --provider=skeleton -v --test --test_args="--ginkgo.focus=Horizontal"

An error happens::

 [sig-autoscaling] [HPA] Horizontal pod autoscaling (scale resource: CPU)
 /go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes/test/e2e/autoscaling/framework.go:22
   [sig-autoscaling] ReplicationController light
 /go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes/test/e2e/autoscaling/framework.go:22
   Should scale from 1 pod to 2 pods [It]
 /go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes/test/e2e/autoscaling/horizontal_pod_autoscaling.go:80

  timeout waiting 15m0s for 2 replicas
  Expected error:
     <*errors.errorString | 0xc420257830>: {
         s: "timed out waiting for the condition",
     }
     timed out waiting for the condition
     not to have occurred

test/e2e/autoscaling/horizontal_pod_autoscaling.go::

 69                 It("Should scale from 1 pod to 2 pods", func() {
 70                         scaleTest := &HPAScaleTest{
 71                                 initPods:                    1,
 72                                 totalInitialCPUUsage:        150,
 73                                 perPodCPURequest:            200,
 74                                 targetCPUUtilizationPercent: 50,
 75                                 minPods:                     1,
 76                                 maxPods:                     2,
 77                                 firstScale:                  2,
 78                         }
 79                         scaleTest.run("rc-light", common.KindRC, rc, f)
 80                 })

The above log doesn't contain current pod number, but we might get it with::

 345 func (rc *ResourceConsumer) WaitForReplicas(desiredReplicas int, duration time.Duration) {
 346         interval := 20 * time.Second
 347         err := wait.PollImmediate(interval, duration, func() (bool, error) {
 348                 replicas := rc.GetReplicas()
 349                 framework.Logf("waiting for %d replicas (current: %d)", desiredReplicas, replicas)  <-- Here -->
 350                 return replicas == desiredReplicas, nil // Expected number of replicas found. Exit.
 351         })
 352         framework.ExpectNoErrorWithOffset(1, err, "timeout waiting %v for %d replicas", duration, desiredReplicas)
 353 }

The log has been output like::

 Sep  1 13:53:50.349: INFO: waiting for 2 replicas (current: 1)
 Sep  1 13:53:56.130: INFO: RC rc-light: sending request to consume 150 millicores
 Sep  1 13:53:56.130: INFO: RC rc-light: sending request to consume 0 of custom metric QPS
 Sep  1 13:53:56.130: INFO: RC rc-light: sending request to consume 0 MB
 Sep  1 13:53:56.131: INFO: ConsumeCustomMetric URL: {https  <nil> 172.27.138.84:6443 /api/v1/namespaces/e2e-tests-horizontal-pod-autoscaling-plmpr/services/rc-light-ctrl/proxy/BumpMetric  false delta=0&durationSec=30&metric=QPS&requestSizeMetrics=10 }
 Sep  1 13:53:56.131: INFO: ConsumeCPU URL: {https  <nil> 172.27.138.84:6443 /api/v1/namespaces/e2e-tests-horizontal-pod-autoscaling-plmpr/services/rc-light-ctrl/proxy/ConsumeCPU  false durationSec=30&millicores=150&requestSizeMillicores=20 }
 Sep  1 13:53:56.132: INFO: ConsumeMem URL: {https  <nil> 172.27.138.84:6443 /api/v1/namespaces/e2e-tests-horizontal-pod-autoscaling-plmpr/services/rc-light-ctrl/proxy/ConsumeMem  false durationSec=30&megabytes=0&requestSizeMegabytes=100 }
 Sep  1 13:54:10.349: INFO: waiting for 2 replicas (current: 1)

So the count is never changed to 2 from 1.

I need to reproduce this problem by hands without e2e test to verify what is lack of feature or something.

The test is::

 116 func (scaleTest *HPAScaleTest) run(name, kind string, rc *common.ResourceConsumer, f *framework.Framework) {
 117         const timeToWait = 15 * time.Minute
 118         rc = common.NewDynamicResourceConsumer(name, kind, int(scaleTest.initPods), int(scaleTest.totalInitialCPUUsage), 0, 0, scaleTest.perPodCPURequest, 200, f)
 119         defer rc.CleanUp()
 120         hpa := common.CreateCPUHorizontalPodAutoscaler(rc, scaleTest.targetCPUUtilizationPercent, scaleTest.minPods, scaleTest.maxPods)
 121         defer common.DeleteHorizontalPodAutoscaler(rc, hpa.Name)
 122         rc.WaitForReplicas(int(scaleTest.firstScale), timeToWait)
 123         if scaleTest.firstScaleStasis > 0 {
 124                 rc.EnsureDesiredReplicas(int(scaleTest.firstScale), scaleTest.firstScaleStasis)
 125         }
 126         if scaleTest.cpuBurst > 0 && scaleTest.secondScale > 0 {
 127                 rc.ConsumeCPU(scaleTest.cpuBurst)
 128                 rc.WaitForReplicas(int(scaleTest.secondScale), timeToWait)
 129         }
 130 }

and the operations are::

 common.NewDynamicResourceConsumer()
 common.CreateCPUHorizontalPodAutoscaler()
 rc.ConsumeCPU()
 rc.WaitForReplicas()

and the timeout happens at rc.WaitForReplicas() call.

common.NewDynamicResourceConsumer() is::

 102 func NewDynamicResourceConsumer(name, kind string, replicas, initCPUTotal, initMemoryTotal, initCustomMetric int, cpuLimit, memLimit int64, f *framework.Framework) *ResourceConsumer {
 103         return newResourceConsumer(name, kind, replicas, initCPUTotal, initMemoryTotal, initCustomMetric, dynamicConsumptionTimeInSeconds,
 104                 dynamicRequestSizeInMillicores, dynamicRequestSizeInMegabytes, dynamicRequestSizeCustomMetric, cpuLimit, memLimit, f)
 105 }



