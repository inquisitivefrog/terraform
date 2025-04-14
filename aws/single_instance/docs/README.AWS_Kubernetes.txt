
tim@Tims-MacBook-Pro prod % ssh -i ~/.aws/bluedragon.pem ubuntu@ec2-18-144-1-5.us-west-1.compute.amazonaws.com
ubuntu@ip-10-0-0-28:~$ mkdir .aws
ubuntu@ip-10-0-0-28:~$ exit
tim@Tims-MacBook-Pro prod % scp -i ~/.aws/bluedragon.pem ~/.aws/config ubuntu@18.144.1.5:~/.aws/config        
config                                                                                                           100%   93     0.6KB/s   00:00    
tim@Tims-MacBook-Pro prod % scp -i ~/.aws/bluedragon.pem ~/.aws/credentials ubuntu@18.144.1.5:~/.aws/credentials
credentials                                                                                                      100%  231     1.5KB/s   00:00    

tim@Tims-MacBook-Pro prod % ssh -i ~/.aws/bluedragon.pem ubuntu@ec2-18-144-1-5.us-west-1.compute.amazonaws.com  
ubuntu@ip-10-0-0-28:~$ cat add_aws_cli.sh 
sudo apt update
sudo apt install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
ubuntu@ip-10-0-0-28:~$ ./add_aws_cli.sh 

ubuntu@ip-10-0-0-28:~$ cat add_kubernetes.sh 
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
ubuntu@ip-10-0-0-28:~$ ./add_kubernetes.sh 


ubuntu@ip-10-0-0-28:~$ aws --version
aws-cli/2.25.11 Python/3.12.9 Linux/5.15.0-1081-aws exe/x86_64.ubuntu.20
ubuntu@ip-10-0-0-28:~$ kubectl version --client
Client Version: v1.32.3
Kustomize Version: v5.5.0

ubuntu@ip-10-0-0-28:~$ aws eks --region us-west-1 update-kubeconfig --name eks-prod-cznz3htc
Added new context arn:aws:eks:us-west-1:084375569056:cluster/eks-prod-cznz3htc to /home/ubuntu/.kube/config
ubuntu@ip-10-0-0-28:~$ kubectl get nodes -o wide
NAME                                      STATUS   ROLES    AGE   VERSION                INTERNAL-IP   EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-10-0-0-37.us-west-1.compute.internal   Ready    <none>   48m   v1.28.15-eks-aeac579   10.0.0.37     <none>        Amazon Linux 2   5.10.234-225.910.amzn2.x86_64   containerd://1.7.25
ip-10-0-0-57.us-west-1.compute.internal   Ready    <none>   49m   v1.28.15-eks-aeac579   10.0.0.57     <none>        Amazon Linux 2   5.10.234-225.910.amzn2.x86_64   containerd://1.7.25
ubuntu@ip-10-0-0-28:~$ kubectl get pods -n kube-system -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP          NODE                                      NOMINATED NODE   READINESS GATES
aws-node-7rjx8             2/2     Running   0          49m   10.0.0.37   ip-10-0-0-37.us-west-1.compute.internal   <none>           <none>
aws-node-gljn8             2/2     Running   0          49m   10.0.0.57   ip-10-0-0-57.us-west-1.compute.internal   <none>           <none>
coredns-59b9f5f4d6-b7mrc   1/1     Running   0          54m   10.0.0.62   ip-10-0-0-57.us-west-1.compute.internal   <none>           <none>
coredns-59b9f5f4d6-h5dmm   1/1     Running   0          54m   10.0.0.58   ip-10-0-0-57.us-west-1.compute.internal   <none>           <none>
kube-proxy-fcnpr           1/1     Running   0          49m   10.0.0.37   ip-10-0-0-37.us-west-1.compute.internal   <none>           <none>
kube-proxy-mgms8           1/1     Running   0          49m   10.0.0.57   ip-10-0-0-57.us-west-1.compute.internal   <none>           <none>

ubuntu@ip-10-0-0-28:~$ kubectl run nginx --image=nginx
pod/nginx created
ubuntu@ip-10-0-0-28:~$ kubectl get pods
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          7s
ubuntu@ip-10-0-0-28:~$ kubectl logs nginx
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2025/04/07 19:54:59 [notice] 1#1: using the "epoll" event method
2025/04/07 19:54:59 [notice] 1#1: nginx/1.27.4
2025/04/07 19:54:59 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14) 
2025/04/07 19:54:59 [notice] 1#1: OS: Linux 5.10.234-225.910.amzn2.x86_64
2025/04/07 19:54:59 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2025/04/07 19:54:59 [notice] 1#1: start worker processes
2025/04/07 19:54:59 [notice] 1#1: start worker process 29
2025/04/07 19:54:59 [notice] 1#1: start worker process 30

ubuntu@ip-10-0-0-28:~$ kubectl logs coredns-59b9f5f4d6-b7mrc -n kube-system
.:53
[INFO] plugin/reload: Running configuration SHA512 = 8a7d59126e7f114ab49c6d2613be93d8ef7d408af8ee61a710210843dc409f03133727e38f64469d9bb180f396c84ebf48a42bde3b3769730865ca9df5eb281c
CoreDNS-1.10.1
linux/amd64, go1.20.4, 84446ec6

ubuntu@ip-10-0-0-28:~$ sudo apt update
Hit:1 http://us-west-1.ec2.archive.ubuntu.com/ubuntu focal InRelease
Get:2 http://us-west-1.ec2.archive.ubuntu.com/ubuntu focal-updates InRelease [128 kB]
Get:3 http://us-west-1.ec2.archive.ubuntu.com/ubuntu focal-backports InRelease [128 kB]
Hit:4 http://security.ubuntu.com/ubuntu focal-security InRelease
Fetched 256 kB in 1s (363 kB/s)
Reading package lists... Done
Building dependency tree       
Reading state information... Done
16 packages can be upgraded. Run 'apt list --upgradable' to see them.
ubuntu@ip-10-0-0-28:~$ kubectl get nodes
NAME                                      STATUS   ROLES    AGE    VERSION
ip-10-0-0-37.us-west-1.compute.internal   Ready    <none>   158m   v1.28.15-eks-aeac579
ip-10-0-0-57.us-west-1.compute.internal   Ready    <none>   158m   v1.28.15-eks-aeac579
ubuntu@ip-10-0-0-28:~$ aws eks --region us-west-1 describe-cluster --name eks-prod-cznz3htc
{
    "cluster": {
        "name": "eks-prod-cznz3htc",
        "arn": "arn:aws:eks:us-west-1:084375569056:cluster/eks-prod-cznz3htc",
        "createdAt": "2025-04-07T18:43:45.488000+00:00",
        "version": "1.28",
        "endpoint": "https://45F2C496BD671CCA526EDED3D52F1BE7.yl4.us-west-1.eks.amazonaws.com",
        "roleArn": "arn:aws:iam::084375569056:role/eks-cluster-role-prod-cznz3htc",
        "resourcesVpcConfig": {
            "subnetIds": [
                "subnet-0b4f820615136bb39",
                "subnet-08be592317746e7d0"
            ],
            "securityGroupIds": [
                "sg-0df8936f375cfe9ab"
            ],
            "clusterSecurityGroupId": "sg-071f669fb9e7e8f14",
            "vpcId": "vpc-07a00178508c7bc0d",
            "endpointPublicAccess": false,
            "endpointPrivateAccess": true,
            "publicAccessCidrs": []
        },
        "kubernetesNetworkConfig": {
            "serviceIpv4Cidr": "172.20.0.0/16",
            "ipFamily": "ipv4",
            "elasticLoadBalancing": {
                "enabled": false
            }
        },
        "logging": {
            "clusterLogging": [
                {
                    "types": [
                        "api",
                        "audit",
                        "authenticator",
                        "controllerManager",
                        "scheduler"
                    ],
                    "enabled": false
                }
            ]
        },
        "identity": {
            "oidc": {
                "issuer": "https://oidc.eks.us-west-1.amazonaws.com/id/45F2C496BD671CCA526EDED3D52F1BE7"
            }
        },
        "status": "ACTIVE",
        "certificateAuthority": {
            "data": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJWlVQTytkL2Rzdk13RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBME1EY3hPRFF5TlRsYUZ3MHpOVEEwTURVeE9EUTNOVGxhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURLRktlbTRhUXVaczBEbDNUK3pBOVFOdlBlU05xSndZRXh4MGtNekl5cVhCaUdOek9VZ3BreU5haEIKdy82MjdYNldsaU16TzY3MkRhcWNveU05TjR4aXBMYURsSm9Qa2dOd0VDUHVKUWFRTVFJTC9KaS9IeXAwWE5RegoreWJ3eElkZld5d0RaTGlWSXdwQkFlWkdma25tN29jSXV6a2QvVHNNb3JMZ3N4QU9DeUpvTkEySGhNY2dvd3dRCjRuWnBVK3EwcmMwN212TkhZUjhYOE5ZbkdxdnErTnYvRUxOY1Mvc0YxVVdiVlVGeVhaWE1sdzBWU01STkI0ZlQKMmRRd1NYdHIyOWRlSEtoSmNUTmpwNkxWbzVTdHk3VEJBODRTOVdBQklMMVhqajVOdDRSaS9oRm4zWDZ1WkRpRAo0ejc3L2lRTWNPZzJoYUNBUmtYQ2o3alJNYmQ1QWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJUcU1LRHlnaFVXQ3pDTnE0VEdPQm0zdnV4OFBUQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQldFYy9TTk05Lwp4ZWNaL1UzTG1jUmdocXE2NlJrSmdXSzhhcFVjTklxZCtpeldyZGlFSUdaU2RCay9oTGtDK21LM2wyOU9HclBkCitEU21yOWRiN2VpVzNwT21peDV5MzlsNU8wbE5LSWRmSUNvM1JVaXgyRE05Y0htZ3J0d2t4MG43NFRYMVErdEQKS05yS20rNEFYeFdxeVR3UWtUZzZ5TUY1NEJpa3RvQ3pRME5xZndjSzRYTnZGNGpNVHF6Y1lHa1FxamlTMklxTQpMc1J6TXNSSG9zU0hEc0xqNDlGUFhCMkFReXd6MTgvOHJBTWdKYms1MXk0MElUWEdFVmYvUEttMlBmMDhDbjFRCktDZEY5VXNTbll5ODFXVjJ1aHVpOE82L2F1TzBoVTV3R3pwYldpZUZxbkVmR01OQk5GWEl6Tlk0WlZRYTFOaFEKVzRLdzhIVEVBR3p2Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
        },
        "platformVersion": "eks.39",
        "tags": {},
        "encryptionConfig": [
            {
                "resources": [
                    "secrets"
                ],
                "provider": {
                    "keyArn": "arn:aws:kms:us-west-1:084375569056:key/5920e296-bf8d-4d26-b089-fb78a50f53a8"
                }
            }
        ],
        "health": {
            "issues": []
        },
        "accessConfig": {
            "authenticationMode": "CONFIG_MAP"
        },
        "upgradePolicy": {
            "supportType": "EXTENDED"
        }
    }
}

ubuntu@ip-10-0-0-28:~$ dig us-west-1.ec2.archive.ubuntu.com

; <<>> DiG 9.18.30-0ubuntu0.20.04.2-Ubuntu <<>> us-west-1.ec2.archive.ubuntu.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 15209
;; flags: qr rd ra; QUERY: 1, ANSWER: 4, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;us-west-1.ec2.archive.ubuntu.com. IN	A

;; ANSWER SECTION:
us-west-1.ec2.archive.ubuntu.com. 14 IN	A	54.241.183.81
us-west-1.ec2.archive.ubuntu.com. 14 IN	A	13.57.245.129
us-west-1.ec2.archive.ubuntu.com. 14 IN	A	54.183.207.82
us-west-1.ec2.archive.ubuntu.com. 14 IN	A	54.193.70.62

;; Query time: 0 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Mon Apr 07 21:37:01 UTC 2025
;; MSG SIZE  rcvd: 125

ubuntu@ip-10-0-0-28:~$ curl dl.k8s.io
<html>
<head><title>302 Found</title></head>
<body>
<center><h1>302 Found</h1></center>
<hr><center>nginx</center>
</body>
</html>

ubuntu@ip-10-0-0-28:~$ aws ec2 describe-security-groups --group-ids sg-037b1aaad101aa109 --region us-west-1
{
    "SecurityGroups": [
        {
            "GroupId": "sg-037b1aaad101aa109",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "tcp",
                    "FromPort": 80,
                    "ToPort": 80,
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "Description": "Allow HTTP to Ubuntu repos",
                            "CidrIp": "13.56.0.0/16"
                        },
                        {
                            "Description": "Allow HTTP to Ubuntu repos",
                            "CidrIp": "54.241.0.0/16"
                        },
                        {
                            "Description": "Allow HTTP to Ubuntu repos",
                            "CidrIp": "54.183.0.0/16"
                        },
                        {
                            "Description": "Allow HTTP to Ubuntu repos",
                            "CidrIp": "91.189.91.0/24"
                        },
                        {
                            "Description": "Allow HTTP to Ubuntu repos",
                            "CidrIp": "185.125.190.0/24"
                        },
                        {
                            "Description": "Allow HTTP to Ubuntu repos",
                            "CidrIp": "54.193.0.0/16"
                        },
                        {
                            "Description": "Allow HTTP to Ubuntu repos",
                            "CidrIp": "34.107.0.0/16"
                        },
                        {
                            "Description": "Allow HTTP to Ubuntu repos",
                            "CidrIp": "176.32.0.0/16"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "-1",
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "Description": "Allow all traffic to laptop and VPC subnets",
                            "CidrIp": "10.0.0.16/28"
                        },
                        {
                            "Description": "Allow all traffic to laptop and VPC subnets",
                            "CidrIp": "77.81.142.250/32"
                        },
                        {
                            "Description": "Allow all traffic to laptop and VPC subnets",
                            "CidrIp": "10.0.0.32/28"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 443,
                    "ToPort": 443,
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "Description": "Allow HTTPS to AWS EKS and Ubuntu repos",
                            "CidrIp": "13.56.0.0/16"
                        },
                        {
                            "Description": "Allow HTTPS to AWS EKS and Ubuntu repos",
                            "CidrIp": "54.183.0.0/16"
                        },
                        {
                            "Description": "Allow HTTPS to AWS EKS and Ubuntu repos",
                            "CidrIp": "91.189.91.0/24"
                        },
                        {
                            "Description": "Allow HTTPS to AWS EKS and Ubuntu repos",
                            "CidrIp": "54.241.0.0/16"
                        },
                        {
                            "Description": "Allow HTTPS to AWS EKS and Ubuntu repos",
                            "CidrIp": "185.125.190.0/24"
                        },
                        {
                            "Description": "Allow HTTPS to AWS EKS and Ubuntu repos",
                            "CidrIp": "54.193.0.0/16"
                        },
                        {
                            "Description": "Allow HTTPS to AWS EKS and Ubuntu repos",
                            "CidrIp": "34.107.0.0/16"
                        },
                        {
                            "Description": "Allow HTTPS to AWS EKS and Ubuntu repos",
                            "CidrIp": "176.32.0.0/16"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                }
            ],
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "public-ec2"
                }
            ],
            "VpcId": "vpc-07a00178508c7bc0d",
            "SecurityGroupArn": "arn:aws:ec2:us-west-1:084375569056:security-group/sg-037b1aaad101aa109",
            "OwnerId": "084375569056",
            "GroupName": "public-ec2",
            "Description": "Allow SSH, ICMP, HTTP, and HTTPS access",
            "IpPermissions": [
                {
                    "IpProtocol": "tcp",
                    "FromPort": 80,
                    "ToPort": 80,
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "Description": "Allow HTTP from my laptop",
                            "CidrIp": "77.81.142.250/32"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 22,
                    "ToPort": 22,
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "Description": "Allow SSH from my laptop",
                            "CidrIp": "77.81.142.250/32"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "icmp",
                    "FromPort": -1,
                    "ToPort": -1,
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "Description": "Allow ICMP (ping) from my laptop",
                            "CidrIp": "77.81.142.250/32"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 443,
                    "ToPort": 443,
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "Description": "Allow HTTPS from my laptop",
                            "CidrIp": "77.81.142.250/32"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                }
            ]
        }
    ]
}
ubuntu@ip-10-0-0-28:~$ curl dl.k8s.io
<html>
<head><title>302 Found</title></head>
<body>
<center><h1>302 Found</h1></center>
<hr><center>nginx</center>
</body>
</html>

ubuntu@ip-10-0-0-28:~$ cat nginx-deployment.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
ubuntu@ip-10-0-0-28:~$ kubectl apply -f nginx-deployment.yaml
deployment.apps/nginx-deployment created
ubuntu@ip-10-0-0-28:~$ aws eks list-nodegroups --cluster-name eks-prod-cznz3htc --region us-west-1
{
    "nodegroups": [
        "ng-prod-cznz3htc"
    ]
}
ubuntu@ip-10-0-0-28:~$ kubectl get pods 
NAME                                READY   STATUS    RESTARTS   AGE
nginx                               1/1     Running   0          129m
nginx-deployment-7c79c4bf97-6f2bp   0/1     Pending   0          4m37s
nginx-deployment-7c79c4bf97-dldhl   1/1     Running   0          4m37s
nginx-deployment-7c79c4bf97-nxvqv   0/1     Pending   0          4m37s


ubuntu@ip-10-0-0-28:~$ kubectl get nodes
NAME                                      STATUS   ROLES    AGE     VERSION
ip-10-0-0-37.us-west-1.compute.internal   Ready    <none>   3h14m   v1.28.15-eks-aeac579
ip-10-0-0-57.us-west-1.compute.internal   Ready    <none>   3h14m   v1.28.15-eks-aeac579
ip-10-0-0-59.us-west-1.compute.internal   Ready    <none>   41s     v1.28.15-eks-aeac579

ubuntu@ip-10-0-0-28:~$ kubectl apply -f nginx-deployment.yaml
deployment.apps/nginx-deployment configured
ubuntu@ip-10-0-0-28:~$ cat nginx-deployment.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values: [nginx]
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80

ubuntu@ip-10-0-0-28:~$ kubectl get pods -o wide
NAME                                READY   STATUS    RESTARTS   AGE     IP          NODE                                      NOMINATED NODE   READINESS GATES
nginx                               1/1     Running   0          158m    10.0.0.44   ip-10-0-0-37.us-west-1.compute.internal   <none>           <none>
nginx-deployment-7c79c4bf97-22hkc   1/1     Running   0          17m     10.0.0.53   ip-10-0-0-59.us-west-1.compute.internal   <none>           <none>
nginx-deployment-7c79c4bf97-hvxcl   1/1     Running   0          17m     10.0.0.56   ip-10-0-0-59.us-west-1.compute.internal   <none>           <none>
nginx-deployment-7c79c4bf97-kmsxs   1/1     Running   0          17m     10.0.0.41   ip-10-0-0-37.us-west-1.compute.internal   <none>           <none>
nginx-deployment-b777cdd69-xrnwp    0/1     Pending   0          3m49s   <none>      <none>                                    <none>           <none>

In Amazon EKS, the control plane (master nodes) is fully managed by AWS—you don’t see or manage them directly. The nodes you see (ip-10-0-0-37, ip-10-0-0-57, ip-10-0-0-59) are all worker nodes in your node group (ng-prod-cznz3htc). Here’s why:
EKS Architecture:
Control Plane: Runs the Kubernetes API server, scheduler, etc., on AWS-managed infrastructure (not in your VPC or node list).
Worker Nodes: These are your EC2 instances (e.g., t3.medium), registered with EKS to run pods. All three are workers.

ubuntu@ip-10-0-0-28:~$ kubectl delete -f nginx-deployment.yaml 
deployment.apps "nginx-deployment" deleted
ubuntu@ip-10-0-0-28:~$ cat nginx-deployment.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values: [nginx]
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80

ubuntu@ip-10-0-0-28:~$ kubectl get pods --all-namespaces -o wide
NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE     IP          NODE                                      NOMINATED NODE   READINESS GATES
kube-system   aws-node-7rjx8             2/2     Running   0          3h43m   10.0.0.37   ip-10-0-0-37.us-west-1.compute.internal   <none>           <none>
kube-system   aws-node-gljn8             2/2     Running   0          3h43m   10.0.0.57   ip-10-0-0-57.us-west-1.compute.internal   <none>           <none>
kube-system   aws-node-lqzr4             2/2     Running   0          29m     10.0.0.59   ip-10-0-0-59.us-west-1.compute.internal   <none>           <none>
kube-system   coredns-59b9f5f4d6-b7mrc   1/1     Running   0          3h49m   10.0.0.62   ip-10-0-0-57.us-west-1.compute.internal   <none>           <none>
kube-system   coredns-59b9f5f4d6-h5dmm   1/1     Running   0          3h49m   10.0.0.58   ip-10-0-0-57.us-west-1.compute.internal   <none>           <none>
kube-system   kube-proxy-b5gbm           1/1     Running   0          29m     10.0.0.59   ip-10-0-0-59.us-west-1.compute.internal   <none>           <none>
kube-system   kube-proxy-fcnpr           1/1     Running   0          3h43m   10.0.0.37   ip-10-0-0-37.us-west-1.compute.internal   <none>           <none>
kube-system   kube-proxy-mgms8           1/1     Running   0          3h43m   10.0.0.57   ip-10-0-0-57.us-west-1.compute.internal   <none>           <none>

ubuntu@ip-10-0-0-28:~$ kubectl apply -f nginx-deployment.yaml 
deployment.apps/nginx-deployment created

ubuntu@ip-10-0-0-28:~$ kubectl get pods --all-namespaces -o wide
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE     IP          NODE                                      NOMINATED NODE   READINESS GATES
default       nginx-deployment-b777cdd69-5lzc6   1/1     Running   0          2m14s   10.0.0.44   ip-10-0-0-37.us-west-1.compute.internal   <none>           <none>
default       nginx-deployment-b777cdd69-jmxx5   1/1     Running   0          2m14s   10.0.0.53   ip-10-0-0-59.us-west-1.compute.internal   <none>           <none>
default       nginx-deployment-b777cdd69-lzjzg   0/1     Pending   0          2m14s   <none>      <none>                                    <none>           <none>
kube-system   aws-node-7rjx8                     2/2     Running   0          3h45m   10.0.0.37   ip-10-0-0-37.us-west-1.compute.internal   <none>           <none>
kube-system   aws-node-gljn8                     2/2     Running   0          3h45m   10.0.0.57   ip-10-0-0-57.us-west-1.compute.internal   <none>           <none>
kube-system   aws-node-lqzr4                     2/2     Running   0          32m     10.0.0.59   ip-10-0-0-59.us-west-1.compute.internal   <none>           <none>
kube-system   coredns-59b9f5f4d6-b7mrc           1/1     Running   0          3h51m   10.0.0.62   ip-10-0-0-57.us-west-1.compute.internal   <none>           <none>
kube-system   coredns-59b9f5f4d6-h5dmm           1/1     Running   0          3h51m   10.0.0.58   ip-10-0-0-57.us-west-1.compute.internal   <none>           <none>
kube-system   kube-proxy-b5gbm                   1/1     Running   0          32m     10.0.0.59   ip-10-0-0-59.us-west-1.compute.internal   <none>           <none>
kube-system   kube-proxy-fcnpr                   1/1     Running   0          3h45m   10.0.0.37   ip-10-0-0-37.us-west-1.compute.internal   <none>           <none>
kube-system   kube-proxy-mgms8                   1/1     Running   0          3h45m   10.0.0.57   ip-10-0-0-57.us-west-1.compute.internal   <none>           <none>



