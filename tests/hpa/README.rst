Test HPA
--------

Creat a deployment which consume CPU resource::

 $ kubectl create -f consume-cpu.yaml

Configure HPA::

 $ kubectl autoscale deployment consume-cpu --cpu-percent=50 --min=1 --max=10

Check the deployment and the hpa condition before hpa works::

 $ kubectl get deployments
 NAME          READY   UP-TO-DATE   AVAILABLE   AGE
 consume-cpu   3/3     3            3           78s
 $
 $ kubectl get hpa
 NAME          REFERENCE                TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
 consume-cpu   Deployment/consume-cpu   250%/50%   1         10        10         2m8s
 $

After hpa works, check them again::

 $ kubectl get deployments
 NAME          READY   UP-TO-DATE   AVAILABLE   AGE
 consume-cpu   10/10   10           10          3m7s
 $
 $ kubectl get hpa
 NAME          REFERENCE                TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
 consume-cpu   Deployment/consume-cpu   250%/50%   1         10        10         3m14s
 $
