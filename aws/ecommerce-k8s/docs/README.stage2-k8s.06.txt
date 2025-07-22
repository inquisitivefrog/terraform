
        
tim@Tims-MBP stage2-k8s % kubectl get configmap aws-auth -n kube-system -o yaml
apiVersion: v1
data:
  mapRoles: |
    - "groups":
      - "system:bootstrappers"
      - "system:nodes"
      "rolearn": "arn:aws:iam::084375569056:role/default-eks-node-group-20250612215659371300000001"
      "username": "system:node:{{EC2PrivateDNSName}}"
    - "groups":
      - "system:masters"
      "rolearn": "arn:aws:iam::084375569056:role/terraform-admin"
      "username": "terraform-admin"
  mapUsers: |
    - userarn: arn:aws:iam::084375569056:user/bluedragon
      username: bluedragon
      groups:
        - system:masters
kind: ConfigMap
metadata:
  creationTimestamp: "2025-06-20T18:00:03Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "10464"
  uid: 91a3e707-adee-461e-89a5-d3bd7e4030ca
tim@Tims-MBP stage2-k8s % kubectl get ingress sample-app -n default -o yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    kubernetes.io/ingress.class: alb
  creationTimestamp: "2025-06-20T18:33:50Z"
  finalizers:
  - ingress.k8s.aws/resources
  generation: 1
  name: sample-app
  namespace: default
  resourceVersion: "7332"
  uid: fc52797e-3279-4300-8d46-aa554bd3d47e
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: sample-app
            port:
              number: 80
        path: /
        pathType: Prefix
status:
  loadBalancer: {}
tim@Tims-MBP stage2-k8s % kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
{"level":"info","ts":"2025-06-20T18:33:24Z","logger":"setup","msg":"starting collect top talkers"}
{"level":"info","ts":"2025-06-20T18:33:24Z","logger":"setup","msg":"starting collect cache size"}
{"level":"info","ts":"2025-06-20T18:33:24Z","msg":"starting server","name":"health probe","addr":"[::]:61779"}
{"level":"info","ts":"2025-06-20T18:33:24Z","logger":"controller-runtime.metrics","msg":"Starting metrics server"}
{"level":"info","ts":"2025-06-20T18:33:24Z","logger":"controller-runtime.webhook","msg":"Starting webhook server"}
{"level":"info","ts":"2025-06-20T18:33:24Z","logger":"controller-runtime.metrics","msg":"Serving metrics server","bindAddress":":8080","secure":false}
{"level":"info","ts":"2025-06-20T18:33:24Z","logger":"controller-runtime.certwatcher","msg":"Updated current TLS certificate"}
{"level":"info","ts":"2025-06-20T18:33:24Z","logger":"controller-runtime.webhook","msg":"Serving webhook server","host":"","port":9443}
{"level":"info","ts":"2025-06-20T18:33:24Z","logger":"controller-runtime.certwatcher","msg":"Starting certificate poll+watcher","interval":10}
{"level":"info","ts":"2025-06-20T18:33:24Z","msg":"attempting to acquire leader lease kube-system/aws-load-balancer-controller-leader..."}
{"level":"error","ts":"2025-06-20T18:33:53Z","msg":"Reconciler error","controller":"ingress","object":{"name":"sample-app","namespace":"default"},"namespace":"default","name":"sample-app","reconcileID":"29aa7811-20a8-4155-948a-ff36de1f35a2","error":"operation error Elastic Load Balancing v2: DescribeLoadBalancers, get identity: get credentials: failed to refresh cached credentials, failed to retrieve credentials, operation error STS: AssumeRoleWithWebIdentity, https response error StatusCode: 403, RequestID: ffe67655-ac7b-4303-9d5f-28c253a4c8c6, api error AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity"}
{"level":"error","ts":"2025-06-20T18:33:55Z","msg":"Reconciler error","controller":"ingress","object":{"name":"sample-app","namespace":"default"},"namespace":"default","name":"sample-app","reconcileID":"737a55a5-7208-41e0-ab78-b6bf7869ff42","error":"operation error Elastic Load Balancing v2: DescribeLoadBalancers, get identity: get credentials: failed to refresh cached credentials, failed to retrieve credentials, operation error STS: AssumeRoleWithWebIdentity, https response error StatusCode: 403, RequestID: 28615fcb-2619-4fdc-8f16-2c2e109f3f05, api error AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity"}
{"level":"error","ts":"2025-06-20T18:34:00Z","msg":"Reconciler error","controller":"ingress","object":{"name":"sample-app","namespace":"default"},"namespace":"default","name":"sample-app","reconcileID":"f8347b6f-a3a9-457d-869e-63ec005622dc","error":"operation error Elastic Load Balancing v2: DescribeLoadBalancers, get identity: get credentials: failed to refresh cached credentials, failed to retrieve credentials, operation error STS: AssumeRoleWithWebIdentity, https response error StatusCode: 403, RequestID: 09ee23b1-032f-45ec-b937-31ed87fe2e0a, api error AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity"}
{"level":"error","ts":"2025-06-20T18:34:11Z","msg":"Reconciler error","controller":"ingress","object":{"name":"sample-app","namespace":"default"},"namespace":"default","name":"sample-app","reconcileID":"b0b44a5a-0611-4e5e-a2a5-106daec2c090","error":"operation error Elastic Load Balancing v2: DescribeLoadBalancers, get identity: get credentials: failed to refresh cached credentials, failed to retrieve credentials, operation error STS: AssumeRoleWithWebIdentity, https response error StatusCode: 403, RequestID: df49e521-3602-4d61-b362-e21090b22a3b, api error AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity"}
{"level":"error","ts":"2025-06-20T18:34:31Z","msg":"Reconciler error","controller":"ingress","object":{"name":"sample-app","namespace":"default"},"namespace":"default","name":"sample-app","reconcileID":"20bd4870-545c-4c65-b02c-ce183d38d2d7","error":"operation error Elastic Load Balancing v2: DescribeLoadBalancers, get identity: get credentials: failed to refresh cached credentials, failed to retrieve credentials, operation error STS: AssumeRoleWithWebIdentity, https response error StatusCode: 403, RequestID: 75ab111e-6e48-47e4-89c3-24fabe452ced, api error AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity"}
{"level":"error","ts":"2025-06-20T18:35:12Z","msg":"Reconciler error","controller":"ingress","object":{"name":"sample-app","namespace":"default"},"namespace":"default","name":"sample-app","reconcileID":"6232e492-4559-460e-b72f-68099a75a48e","error":"operation error Elastic Load Balancing v2: DescribeLoadBalancers, get identity: get credentials: failed to refresh cached credentials, failed to retrieve credentials, operation error STS: AssumeRoleWithWebIdentity, https response error StatusCode: 403, RequestID: b9f422cc-3f06-4322-95a4-7f9f1a3f01f5, api error AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity"}
{"level":"error","ts":"2025-06-20T18:36:34Z","msg":"Reconciler error","controller":"ingress","object":{"name":"sample-app","namespace":"default"},"namespace":"default","name":"sample-app","reconcileID":"9dd1af24-6b2c-43ec-ae1d-3078afc30650","error":"operation error Elastic Load Balancing v2: DescribeLoadBalancers, get identity: get credentials: failed to refresh cached credentials, failed to retrieve credentials, operation error STS: AssumeRoleWithWebIdentity, https response error StatusCode: 403, RequestID: 0c044a9d-bdfa-44dd-a900-ef83db8ff012, api error AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity"}
{"level":"error","ts":"2025-06-20T18:39:18Z","msg":"Reconciler error","controller":"ingress","object":{"name":"sample-app","namespace":"default"},"namespace":"default","name":"sample-app","reconcileID":"616ca1e9-18cd-4576-ad98-1206662e339e","error":"operation error Elastic Load Balancing v2: DescribeLoadBalancers, get identity: get credentials: failed to refresh cached credentials, failed to retrieve credentials, operation error STS: AssumeRoleWithWebIdentity, https response error StatusCode: 403, RequestID: f92646c4-cf9f-42ba-8920-88f066c2a53a, api error AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity"}
{"level":"error","ts":"2025-06-20T18:44:46Z","msg":"Reconciler error","controller":"ingress","object":{"name":"sample-app","namespace":"default"},"namespace":"default","name":"sample-app","reconcileID":"d6da51c9-0a41-4089-80b3-67130ae3a3c5","error":"operation error Elastic Load Balancing v2: DescribeLoadBalancers, get identity: get credentials: failed to refresh cached credentials, failed to retrieve credentials, operation error STS: AssumeRoleWithWebIdentity, https response error StatusCode: 403, RequestID: 5ff7c1fd-9d76-4abd-a945-bf41ea8b4081, api error AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity"}
{"level":"error","ts":"2025-06-20T18:55:41Z","msg":"Reconciler error","controller":"ingress","object":{"name":"sample-app","namespace":"default"},"namespace":"default","name":"sample-app","reconcileID":"264ec65c-6fbd-423a-a945-f52c852225cb","error":"operation error Elastic Load Balancing v2: DescribeLoadBalancers, get identity: get credentials: failed to refresh cached credentials, failed to retrieve credentials, operation error STS: AssumeRoleWithWebIdentity, https response error StatusCode: 403, RequestID: 3b604561-6204-409c-b106-6b15d6f86ae8, api error AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity"}


tim@Tims-MBP stage2-k8s % kubectl get pods -n default -l app=sample-app
NAME                         READY   STATUS    RESTARTS   AGE
sample-app-95d9f8557-r7xg4   1/1     Running   0          25m
sample-app-95d9f8557-wgrjf   1/1     Running   0          25m
tim@Tims-MBP stage2-k8s % kubectl describe pod -n default -l app=sample-app
Name:             sample-app-95d9f8557-r7xg4
Namespace:        default
Priority:         0
Service Account:  default
Node:             ip-10-0-1-33.ec2.internal/10.0.1.33
Start Time:       Fri, 20 Jun 2025 11:33:42 -0700
Labels:           app=sample-app
                  pod-template-hash=95d9f8557
Annotations:      <none>
Status:           Running
IP:               10.0.1.112
IPs:
  IP:           10.0.1.112
Controlled By:  ReplicaSet/sample-app-95d9f8557
Containers:
  sample-app:
    Container ID:   containerd://6b78bd0f4797e70c1d8512b7ad69030008d862f167b56ab46fb5bb1955b253a6
    Image:          nginx:latest
    Image ID:       docker.io/library/nginx@sha256:6784fb0834aa7dbbe12e3d7471e69c290df3e6ba810dc38b34ae33d3c1c05f7d
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Fri, 20 Jun 2025 11:33:45 -0700
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-ql8xw (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-ql8xw:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  25m   default-scheduler  Successfully assigned default/sample-app-95d9f8557-r7xg4 to ip-10-0-1-33.ec2.internal
  Normal  Pulling    25m   kubelet            Pulling image "nginx:latest"
  Normal  Pulled     25m   kubelet            Successfully pulled image "nginx:latest" in 2.928s (2.928s including waiting)
  Normal  Created    25m   kubelet            Created container: sample-app
  Normal  Started    25m   kubelet            Started container sample-app


Name:             sample-app-95d9f8557-wgrjf
Namespace:        default
Priority:         0
Service Account:  default
Node:             ip-10-0-2-158.ec2.internal/10.0.2.158
Start Time:       Fri, 20 Jun 2025 11:33:42 -0700
Labels:           app=sample-app
                  pod-template-hash=95d9f8557
Annotations:      <none>
Status:           Running
IP:               10.0.2.230
IPs:
  IP:           10.0.2.230
Controlled By:  ReplicaSet/sample-app-95d9f8557
Containers:
  sample-app:
    Container ID:   containerd://97a4aa68fd5539ad9e9b99008fab7efd992f789fe7ee804a29ec70ecc3a916a8
    Image:          nginx:latest
    Image ID:       docker.io/library/nginx@sha256:6784fb0834aa7dbbe12e3d7471e69c290df3e6ba810dc38b34ae33d3c1c05f7d
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Fri, 20 Jun 2025 11:33:45 -0700
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-xqp42 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-xqp42:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  25m   default-scheduler  Successfully assigned default/sample-app-95d9f8557-wgrjf to ip-10-0-2-158.ec2.internal
  Normal  Pulling    25m   kubelet            Pulling image "nginx:latest"
  Normal  Pulled     25m   kubelet            Successfully pulled image "nginx:latest" in 2.944s (2.944s including waiting)
  Normal  Created    25m   kubelet            Created container: sample-app
  Normal  Started    25m   kubelet            Started container sample-app
tim@Tims-MBP stage2-k8s % 

