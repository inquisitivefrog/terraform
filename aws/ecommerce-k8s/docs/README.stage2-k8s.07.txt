
tim@Tims-MacBook-Pro stage2-k8s % kubectl get nodes -o wide
NAME                        STATUS   ROLES    AGE   VERSION                INTERNAL-IP   EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-10-0-1-34.ec2.internal   Ready    <none>   17h   v1.29.15-eks-473151a   10.0.1.34     <none>        Amazon Linux 2   5.10.237-230.949.amzn2.x86_64   containerd://1.7.27
ip-10-0-2-44.ec2.internal   Ready    <none>   17h   v1.29.15-eks-473151a   10.0.2.44     <none>        Amazon Linux 2   5.10.237-230.949.amzn2.x86_64   containerd://1.7.27

tim@Tims-MacBook-Pro stage2-k8s % kubectl get services -o wide
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE   SELECTOR
kubernetes   ClusterIP   172.20.0.1      <none>        443/TCP        17h   <none>
sample-app   NodePort    172.20.34.232   <none>        80:30080/TCP   79m   app=sample-app

tim@Tims-MacBook-Pro stage2-k8s % kubectl get pods --all-namespaces -o wide
NAMESPACE     NAME                         READY   STATUS    RESTARTS   AGE   IP           NODE                        NOMINATED NODE   READINESS GATES
default       sample-app-95d9f8557-glx68   1/1     Running   0          79m   10.0.1.127   ip-10-0-1-34.ec2.internal   <none>           <none>
kube-system   aws-node-pj2sf               2/2     Running   0          17h   10.0.1.34    ip-10-0-1-34.ec2.internal   <none>           <none>
kube-system   aws-node-vs9lx               2/2     Running   0          17h   10.0.2.44    ip-10-0-2-44.ec2.internal   <none>           <none>
kube-system   coredns-54d6f577c6-4l9z4     1/1     Running   0          17h   10.0.2.226   ip-10-0-2-44.ec2.internal   <none>           <none>
kube-system   coredns-54d6f577c6-cz67l     1/1     Running   0          17h   10.0.1.48    ip-10-0-1-34.ec2.internal   <none>           <none>
kube-system   kube-proxy-9t5cf             1/1     Running   0          17h   10.0.1.34    ip-10-0-1-34.ec2.internal   <none>           <none>
kube-system   kube-proxy-m74dd             1/1     Running   0          17h   10.0.2.44    ip-10-0-2-44.ec2.internal   <none>           <none>
tim@Tims-MacBook-Pro stage2-k8s % kubectl get deployments --all-namespaces -o wide
NAMESPACE     NAME         READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                                                                        SELECTOR
default       sample-app   1/1     1            1           80m   sample-app   nginx:latest                                                                  app=sample-app
kube-system   coredns      2/2     2            2           17h   coredns      602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/coredns:v1.11.1-eksbuild.4   eks.amazonaws.com/component=coredns,k8s-app=kube-dns

tim@Tims-MacBook-Pro stage2-k8s % kubectl get pods -n default
NAME                         READY   STATUS    RESTARTS   AGE
sample-app-95d9f8557-glx68   1/1     Running   0          82m
tim@Tims-MacBook-Pro stage2-k8s % kubectl get svc -n default
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   172.20.0.1      <none>        443/TCP        17h
sample-app   NodePort    172.20.34.232   <none>        80:30080/TCP   82m
tim@Tims-MacBook-Pro stage2-k8s % kubectl port-forward svc/sample-app 8080:80 -n default
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
Handling connection for 8080
Handling connection for 8080
Handling connection for 8080
Handling connection for 8080
Handling connection for 8080

tim@Tims-MacBook-Pro stage2-k8s % curl -X GET http://localhost:8080/
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
tim@Tims-MacBook-Pro stage2-k8s % 


tim@Tims-MacBook-Pro stage2-k8s % aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1 --profile terraform-admin
Updated context arn:aws:eks:us-east-1:084375569056:cluster/ecommerce-cluster in /Users/tim/.kube/config

tim@Tims-MacBook-Pro stage2-k8s % kubectl get ingress -n default
NAME                 CLASS   HOSTS   ADDRESS   PORTS   AGE
sample-app-ingress   alb     *                 80      91s

tim@Tims-MacBook-Pro stage2-k8s % aws logs describe-log-streams --log-group-name /aws/eks/ecommerce-cluster/cluster
{
    "logStreams": [
        {
            "logStreamName": "authenticator-5197d3ff5fd87269c5aa01e8f9658d6d",
            "creationTime": 1750639015103,
            "firstEventTimestamp": 1750639010045,
            "lastEventTimestamp": 1750699750045,
            "lastIngestionTime": 1750699755050,
            "uploadSequenceToken": "49039859634787570093721792932722779157800248369060037110",
            "arn": "arn:aws:logs:us-east-1:084375569056:log-group:/aws/eks/ecommerce-cluster/cluster:log-stream:authenticator-5197d3ff5fd87269c5aa01e8f9658d6d",
            "storedBytes": 0
        },
        {
            "logStreamName": "authenticator-7abb0c93363511861c677993824f7ab9",
            "creationTime": 1750638666357,
            "firstEventTimestamp": 1750638661304,
            "lastEventTimestamp": 1750701099304,
            "lastIngestionTime": 1750701099475,
            "uploadSequenceToken": "49039859634789357141070026068245209071768918993871356179",
            "arn": "arn:aws:logs:us-east-1:084375569056:log-group:/aws/eks/ecommerce-cluster/cluster:log-stream:authenticator-7abb0c93363511861c677993824f7ab9",
            "storedBytes": 0
        },
        {
            "logStreamName": "cloud-controller-manager-5197d3ff5fd87269c5aa01e8f9658d6d",
            "creationTime": 1750639015158,
            "firstEventTimestamp": 1750638957000,
            "lastEventTimestamp": 1750638960000,
            "lastIngestionTime": 1750639020337,
            "uploadSequenceToken": "49039859634706839812886230857452823818832962090425958740",
            "arn": "arn:aws:logs:us-east-1:084375569056:log-group:/aws/eks/ecommerce-cluster/cluster:log-stream:cloud-controller-manager-5197d3ff5fd87269c5aa01e8f9658d6d",
            "storedBytes": 0
        },

