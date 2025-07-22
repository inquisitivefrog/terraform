
tim@Tims-MacBook-Pro stage2-k8s % aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1 --profile default
Updated context arn:aws:eks:us-east-1:084375569056:cluster/ecommerce-cluster in /Users/tim/.kube/config

tim@Tims-MacBook-Pro stage2-k8s % aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1 --profile terraform-admin
Updated context arn:aws:eks:us-east-1:084375569056:cluster/ecommerce-cluster in /Users/tim/.kube/config
tim@Tims-MacBook-Pro stage2-k8s % kubectl config current-context
arn:aws:eks:us-east-1:084375569056:cluster/ecommerce-cluster
tim@Tims-MacBook-Pro stage2-k8s % terraform init -backend-config=backend.hcl
Initializing the backend...
Initializing provider plugins...
- terraform.io/builtin/terraform is built in to Terraform
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/kubernetes from the dependency lock file
- Reusing previous version of hashicorp/helm from the dependency lock file
- Using previously-installed hashicorp/helm v3.0.1
- Using previously-installed hashicorp/aws v5.95.0
- Using previously-installed hashicorp/kubernetes v2.37.1

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

tim@Tims-MacBook-Pro stage2-k8s % kubectl get nodes
NAME                        STATUS   ROLES    AGE   VERSION
ip-10-0-1-34.ec2.internal   Ready    <none>   19h   v1.29.15-eks-473151a
ip-10-0-2-44.ec2.internal   Ready    <none>   19h   v1.29.15-eks-473151a
tim@Tims-MacBook-Pro stage2-k8s % kubectl get pods --all-namespaces
NAMESPACE     NAME                                            READY   STATUS    RESTARTS   AGE
default       sample-app-95d9f8557-glx68                      1/1     Running   0          3h
kube-system   aws-load-balancer-controller-567df8f55c-9wbcj   1/1     Running   0          74m
kube-system   aws-load-balancer-controller-567df8f55c-bccd4   1/1     Running   0          74m
kube-system   aws-node-pj2sf                                  2/2     Running   0          19h
kube-system   aws-node-vs9lx                                  2/2     Running   0          19h
kube-system   coredns-54d6f577c6-4l9z4                        1/1     Running   0          19h
kube-system   coredns-54d6f577c6-cz67l                        1/1     Running   0          19h
kube-system   kube-proxy-9t5cf                                1/1     Running   0          19h
kube-system   kube-proxy-m74dd                                1/1     Running   0          19h

tim@Tims-MacBook-Pro stage2-k8s % helm version
version.BuildInfo{Version:"v3.18.2", GitCommit:"04cad4610054e5d546aa5c5d9c1b1d5cf68ec1f8", GitTreeState:"clean", GoVersion:"go1.24.3"}
tim@Tims-MacBook-Pro stage2-k8s % aws sts get-caller-identity --profile terraform-admin
{
    "UserId": "AROARHJJNAKQFK6GAL46Y:botocore-session-1750708065",
    "Account": "084375569056",
    "Arn": "arn:aws:sts::084375569056:assumed-role/terraform-admin/botocore-session-1750708065"
}
tim@Tims-MacBook-Pro stage2-k8s % aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1 --profile terraform-admin
Updated context arn:aws:eks:us-east-1:084375569056:cluster/ecommerce-cluster in /Users/tim/.kube/config
tim@Tims-MacBook-Pro stage2-k8s % kubectl config current-context
arn:aws:eks:us-east-1:084375569056:cluster/ecommerce-cluster

tim@Tims-MacBook-Pro stage2-k8s % kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
NAME                                            READY   STATUS    RESTARTS   AGE
aws-load-balancer-controller-567df8f55c-9wbcj   1/1     Running   0          88m
aws-load-balancer-controller-567df8f55c-bccd4   1/1     Running   0          88m

tim@Tims-MacBook-Pro stage2-k8s % kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
NAME                                            READY   STATUS    RESTARTS   AGE
aws-load-balancer-controller-567df8f55c-lgg7t   1/1     Running   0          59s
aws-load-balancer-controller-567df8f55c-zz8dc   1/1     Running   0          59s
tim@Tims-MacBook-Pro stage2-k8s % kubectl get serviceaccount aws-load-balancer-controller -n kube-system -o yaml
apiVersion: v1
automountServiceAccountToken: true
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::084375569056:role/ecommerce-cluster-alb-controller
    meta.helm.sh/release-name: aws-load-balancer-controller
    meta.helm.sh/release-namespace: kube-system
  creationTimestamp: "2025-06-23T20:44:58Z"
  labels:
    app.kubernetes.io/instance: aws-load-balancer-controller
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: aws-load-balancer-controller
    app.kubernetes.io/version: v2.13.3
    helm.sh/chart: aws-load-balancer-controller-1.13.3
  name: aws-load-balancer-controller
  namespace: kube-system
  resourceVersion: "203397"
  uid: b5cc5842-37a5-47c5-8f84-ced66d3c2132
tim@Tims-MacBook-Pro stage2-k8s % kubectl get ingress -n default -o wide
NAME                 CLASS   HOSTS   ADDRESS   PORTS   AGE
sample-app-ingress   alb     *                 80      143m

tim@Tims-MacBook-Pro stage1-infra % kubectl get ingress -n default -o wide                                                  
NAME                 CLASS   HOSTS   ADDRESS                                                                 PORTS   AGE
sample-app-ingress   alb     *       k8s-default-sampleap-e38fe595da-199319787.us-east-1.elb.amazonaws.com   80      165m
tim@Tims-MacBook-Pro stage1-infra % ping -c 1 k8s-default-sampleap-e38fe595da-199319787.us-east-1.elb.amazonaws.com
PING k8s-default-sampleap-e38fe595da-199319787.us-east-1.elb.amazonaws.com (23.22.109.243): 56 data bytes

--- k8s-default-sampleap-e38fe595da-199319787.us-east-1.elb.amazonaws.com ping statistics ---
1 packets transmitted, 0 packets received, 100.0% packet loss


tim@Tims-MacBook-Pro stage1-infra % curl -X GET http://k8s-default-sampleap-e38fe595da-199319787.us-east-1.elb.amazonaws.com
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


tim@Tims-MacBook-Pro stage1-infra % kubectl get ingress -n default -o wide
NAME                 CLASS   HOSTS   ADDRESS                                                                 PORTS   AGE
sample-app-ingress   alb     *       k8s-default-sampleap-e38fe595da-199319787.us-east-1.elb.amazonaws.com   80      177m
tim@Tims-MacBook-Pro stage1-infra % kubectl describe ingress sample-app-ingress -n default
Name:             sample-app-ingress
Labels:           <none>
Namespace:        default
Address:          k8s-default-sampleap-e38fe595da-199319787.us-east-1.elb.amazonaws.com
Ingress Class:    alb
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /   sample-app:80 (10.0.1.127:80)
Annotations:  alb.ingress.kubernetes.io/scheme: internet-facing
              alb.ingress.kubernetes.io/target-type: ip
Events:
  Type     Reason                  Age                From     Message
  ----     ------                  ----               ----     -------
  Warning  FailedBuildModel        58m                ingress  Failed build model due to operation error Elastic Load Balancing v2: DescribeLoadBalancers, get identity: get credentials: failed to refresh cached credentials, failed to retrieve credentials, operation error STS: AssumeRoleWithWebIdentity, https response error StatusCode: 403, RequestID: 93926ac5-b0b9-43cd-bd61-ce58f53e6cca, api error AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity
  Warning  FailedBuildModel        35m                ingress  Failed build model due to operation error EC2: CreateSecurityGroup, https response error StatusCode: 403, RequestID: 9e30442f-2c82-412c-9390-39a018b49870, api error UnauthorizedOperation: You are not authorized to perform this operation. User: arn:aws:sts::084375569056:assumed-role/ecommerce-cluster-alb-controller/1750711517954784008 is not authorized to perform: ec2:CreateSecurityGroup on resource: arn:aws:ec2:us-east-1:084375569056:vpc/vpc-097127ba3fab8eeda because no identity-based policy allows the ec2:CreateSecurityGroup action. Encoded authorization failure message: O1Lm2_UeP0zZ1jvJ8AgDWARNRoCz55TvaueyIrrHcKArDzWRBn2Q4WjTYuIWafcTpTWwhhrYTYV1lDemAne5X5Ay1bFq6iOpyRNkjO6WuDvsclGvNY5gf7MXmgo0L7XrQMjPatkaTJC5j4CChhCrUzAZRF3rC6D2KZQg0uEvSSfNEBfeo_o62ojXCzwUpFGqbh32GNqscZ7WJTptv2-WnNa5cozUepOEKiH07JmIcesbAPiwibOo5CQuNRE8NavfdwypwcA62q7bXE7K-_O_LPOn7g0i2jk52u2uEHdJ5Lj43U32mYCCDRTd2b0qeTI8C5z1TqBrDiQECRoawtlgLuK8MU6sdnJd_z8QVpNIFAb149p5EGgRoJD2TJQS3_SlGLOJNUG9hWWBD50FHSN4OcQnevbAbUCsE9r0hwLhMG588C52hunA-RJKGXVhRESM3HP3qhE0A6yAa93bfRBm60IRuCJ4YXOjVbe8R_FcMrEhQzwWiewHj7p9YHpWAjQXXXSks-cmJwkBuUaEesf1Daaoqil3Yt0gOrDQVL5Fw1iMirhaEPeewXJWcWOOUe1Avfxqjaj3kcl2hnHqJDVk4X1rkilSIoTSdND3CNkBqFF_GRCRg1xO-x0USjS6UGVCavNzQvf5IKRu
  Warning  FailedBuildModel        35m                ingress  Failed build model due to operation error EC2: CreateSecurityGroup, https response error StatusCode: 403, RequestID: ca9b0a83-1fd5-4aa7-99aa-e2ff71744353, api error UnauthorizedOperation: You are not authorized to perform this operation. User: arn:aws:sts::084375569056:assumed-role/ecommerce-cluster-alb-controller/1750711517954784008 is not authorized to perform: ec2:CreateSecurityGroup on resource: arn:aws:ec2:us-east-1:084375569056:vpc/vpc-097127ba3fab8eeda because no identity-based policy allows the ec2:CreateSecurityGroup action. Encoded authorization failure message: 5qosPEVAzAyhyHRytwR3SHZwKfzH48pxEFJpoyWv5R12O92dz2BEqt_j1x_OPmwAAxJ4yjVyqg2LiFjQCyLQxpe__JpUANeW3jnUWxTwTBtCZdXCN0mv2xZbpYAKBkxo1SVdfujCW-03MRNkHnUUM0uKkvIdF-8ZhqZnnO79GNoNs71ggTctMNj0lj7o4rx5KYzJlVGvzM8oT9t-DKQ_hSq8F94xbJ3rQzYkA6kJKc990F8slW4yzswHN-F_H-8NYmQKMQdNXcpBWq1Um0eK4vrDZ2PflcC8KlPoK98z3vJDmQxZV_gEKlmhhK5-MniiJ859xOBnPFffDdkKVuJo-yQMqjBQkI3R9P11U8By3WzwoboiAahS2u3GOAO-FHiOy3K9tKH56trkMw01IDB7zxhQ6ocTRiZ8t7QFIdAAUOMkxrVBWGrBE6nx2w7iaM0b9hLRUZ2f2ACcK1v-hx-BL8_ZLu0tw8mgrMdiGdllsMykzxETzN-lezLLfeO5uBHnTVYpZBXl0e-gL53jfe4xXWDrQfXNLgmLOTVqoh3ke1chkkGF7XJyUGRWv-f8j8jg5aOMpXjPz6TUTVAiwCdlGf6t2Addla0bGNJOlKOUFvhCFschTO2aWZHY2xX-yT-euDTQ1oZtJ15x
  Warning  FailedBuildModel        35m                ingress  Failed build model due to operation error EC2: CreateSecurityGroup, https response error StatusCode: 403, RequestID: f84a9183-5111-49d0-9aab-52810da22d2e, api error UnauthorizedOperation: You are not authorized to perform this operation. User: arn:aws:sts::084375569056:assumed-role/ecommerce-cluster-alb-controller/1750711517954784008 is not authorized to perform: ec2:CreateSecurityGroup on resource: arn:aws:ec2:us-east-1:084375569056:vpc/vpc-097127ba3fab8eeda because no identity-based policy allows the ec2:CreateSecurityGroup action. Encoded authorization failure message: 2Cwk_7WRygYikZMaNPTKQwNlQYsLuBuTobYsW2mCIfJI7vfaWVZhNWbxemq1lzgWwqfou0jPepjvlOa3KO0DaaaJiRAFKc_3RFFYZj5d-n_7INruJYO1e-RikYb8Z42Mje16VncOFhndjSJCY360gZQixzwJVHbSSdtlDJmRYvEbJ9cnhCrMPQic1WP87oeosiestVXgBqIRli7ofIG6g5AI5QiNivNtXcQRkShgaa82uOsswQHO5itRbRGoZy1x6RUUbDSJ50mSKXhSw7-IHVj7orinJ1U6akkUUW1g8OIdnrnt51c5pkhkL159SKGEuyYEwfOEBUxS3P_1MxAz_f35Grohce3IievGlapRsTb6o2OAYY915iTCW7913ONrKoVazb8QXiseJkM3s66ZKJi5ze44sKe-uB5OEJOEmsPJVxwBis2XAlo3GPg_7D31ESUiMDjGqF9aGgUucX6kKjt5kYQCNMQNEFQE4S7IyWMoPUY0Dc5DfrPMAX0YKUmlV0qgWBcmHpRjWfE4jfBSGvwGTHvrM69G-9Nbowt9WjB_A_YbpTR7_l7DIHrSQMB9EAw-vFgo4r74wI6Sx2rBTvg8TlMnV6koUwAAHbDHBzISJfi_eb1Sdm3sy968JD4MUYZSnMVTReq-
  Warning  FailedBuildModel        35m                ingress  Failed build model due to operation error EC2: CreateSecurityGroup, https response error StatusCode: 403, RequestID: 13bc2d31-0529-4c3e-8685-ccfac4d0b096, api error UnauthorizedOperation: You are not authorized to perform this operation. User: arn:aws:sts::084375569056:assumed-role/ecommerce-cluster-alb-controller/1750711517954784008 is not authorized to perform: ec2:CreateSecurityGroup on resource: arn:aws:ec2:us-east-1:084375569056:vpc/vpc-097127ba3fab8eeda because no identity-based policy allows the ec2:CreateSecurityGroup action. Encoded authorization failure message: Y2JnPbpR1DLb_hb4vrCzgVckRBLPk-xjzpUxC1s_nVz8tWwRU5BSUjxC3t-nUN-iedXl5WAF1eki1J_x37dfBw-vY0h_IbdFmodTbB-ryjIKQ7LdQLY5hbiLICVPEIlGcuAPnzH96Nq2RQm37ccmAWkQJX1a9_C0Qi82-CpdUiyviwyk_Kiw-fLH2TE0amvzn4tNPnNd1R7dB80QzlaZuPf5iCNX_1uNNXOxBX_Ew2oWAML2I258CWuHslNlGgySYrts7nPLIS33UXxUyb1Xw20d-hRuuuZg2KVec23f6CHm5dIUR2jPROxAZe6i6Lnm3e1yEcOQ5ymM3wmlmLmaGTbW5RL1W0ElJTc5U2oDzMlhNFM96PNZQJIGyJIlzNlpRfGSFufQ6dS_8hTzxEgW-NITbIgESN2zHL6TikblJGN0YgLQayNM2pf0MYlHFxyb2id-eTj3Ycntx1_BTrudEjWn3haU6PzjSWs9NHAjj3FHoLCyxAS9TvHUQ3VGRqlGEPM3hY_EDBcAPW5-GNOuwLScJmdXhO3T2xbvetjxMBkU6l0Zpa8TiXdtLEX-EVczp-dpMbzVQc_2OWSY6Cv0mP92SQglzFLH9eIJgsVaa_TIm0WF5e11Hv2-ywpUAhVPIvQBh1bCZDuZQA
  Warning  FailedBuildModel        35m                ingress  Failed build model due to operation error EC2: CreateSecurityGroup, https response error StatusCode: 403, RequestID: 9b019085-3779-4991-a157-7e4d7fa9522e, api error UnauthorizedOperation: You are not authorized to perform this operation. User: arn:aws:sts::084375569056:assumed-role/ecommerce-cluster-alb-controller/1750711517954784008 is not authorized to perform: ec2:CreateSecurityGroup on resource: arn:aws:ec2:us-east-1:084375569056:vpc/vpc-097127ba3fab8eeda because no identity-based policy allows the ec2:CreateSecurityGroup action. Encoded authorization failure message: zAuZ58Gp9BGuK2_04Alz7G2gZn-CxBkkmE5hl3yCj4PUPetf9Fpd6drg5X6zljNdV0PS4Q_To3ycRRmtNkD8199i1a4_ECevTcJyvRJzS_sBt8AU7QC7VUmekd8C8Sr2VuxSRePZBW3_2godjvdPTNDInBSl2NC8awH0loJn7bj3TuXyQ9TmUKeLAdb7LR_g7l4pNXOYhIpQ9Sz1kPM12C2Z3C7tacm0r-oAVtoUG1o9NjxvXsfvJ24muSF1qVgssiUKWIS9tscuM6Wq8NAzxbbUTtFpgn8DXmXQCbx81lI4kRBQ-TsWsmgCbAp_SzuCeTqSy8zb4kJ0mekOt8V9Vh93OnsI_CmZRSWza3o_i7pAQmzblTRqbKULnDFlXHE74ZEAgzM2g7YGqF1XFb3X-gN9zvtU6SrBLa6Iaw9yTrTqM07ID13RreGL01Dx22bptNyGlzKwff0pcO_zMNq7sP1GEpmupphz8dhqvIILCTPju6PZQffc-vZ-vaeWPno8ktz4G0-8zz2reZwDXhK4_9mxzRcqcoCCMVCQpj-SOzxpjRp1yRLEZDL04P84H7W1HIqVMwLthJ9v5fSBBoAocBubH_yY_n2cvKjyqa4yVgJyfstyoJs2jVcn-6XznvfvKnKhcN2DYuQE
  Warning  FailedBuildModel        35m                ingress  Failed build model due to operation error EC2: CreateSecurityGroup, https response error StatusCode: 403, RequestID: f33bbb08-9255-4840-bcf0-e4fef7a8893a, api error UnauthorizedOperation: You are not authorized to perform this operation. User: arn:aws:sts::084375569056:assumed-role/ecommerce-cluster-alb-controller/1750711517954784008 is not authorized to perform: ec2:CreateSecurityGroup on resource: arn:aws:ec2:us-east-1:084375569056:vpc/vpc-097127ba3fab8eeda because no identity-based policy allows the ec2:CreateSecurityGroup action. Encoded authorization failure message: qJ4rcuGPohlJDXziAEzXVxHIO9y-1xewtCUP-miAdMNMTilETUruO9SLrTU1PfGu38Borns4h-pj2slc5VcO2TqHYisj1iDyT32gjzSfeL-2VZLNrvou7OWNzybUvRN_gdS8EDtzwAZGcp7jVmOT62L6A_tqy5xHbOhlG6JvJj1ZMm6G--qKVsowbzahpUP3P1OXQmtQqZSPoeWqQSNE5rWEJDXcQY2Orx8InyBxc2eBFH8Z4EdS3L-YQ3ya0mF9CyUnatFidqv5KMmXRWL-HUdX5PZn6Fp8FUPDUGxAQGleCfO7ZrZtpINSsMa7pshEdPpX7XGqloGQlcUVohkqvlV2mK4N_fog6pxPA5utKRtavt_s9By92Vz-TmQ8O_lRCcYFzXSukCBKX4nUpKqUc-iL7fQKfNs-xUOVtcMTOBhoGoPhc7UJSitKJcmsx7oxr2CIcniGPs_3tZham7m7HBjbGDLdwEQAxJVyznj4ugNjpiZ_ncbKm3eyJXIsX72nValv9yDI-hkS1v2FkVELjrTYzqkBNTz_s-s6K_fJyOMiJJSFanbYt-bxKLJWQlTbJCRiWuiJUQQdvQzPTLR3Fvux3PDQec0WBahwGWMBVlKJZLcJXFgQd58PH4BvY3SJ0IIcfmOcL-8J
  Warning  FailedBuildModel        35m                ingress  Failed build model due to operation error EC2: CreateSecurityGroup, https response error StatusCode: 403, RequestID: f3d83c44-99bf-4398-bdd4-ffc27a36dc87, api error UnauthorizedOperation: You are not authorized to perform this operation. User: arn:aws:sts::084375569056:assumed-role/ecommerce-cluster-alb-controller/1750711517954784008 is not authorized to perform: ec2:CreateSecurityGroup on resource: arn:aws:ec2:us-east-1:084375569056:vpc/vpc-097127ba3fab8eeda because no identity-based policy allows the ec2:CreateSecurityGroup action. Encoded authorization failure message: 6-TosSlxTYLzurfkEq0eVsX5fly0lutENeKTOS7bDOYA0KAle5kU5m0IDKUVLd5HfyrAI9fn-pVH5MjFqc0D52D7mTocCxdYA1SBmYjGsPMLqRl_2DAsNEZHc88XIm_YCexGA-nh1ipBdkwm2NxvD3OF7lp3FOis0K2PyXwxbJd85UNL-SlPmzqVUPw8KTK_JWQFj8zU0JzwWOUAnzQNa45FPPhU9ZkHy2hEnCbK-WgTP9Gs1aXH30GZMAgCcQFRKs1rIZFwyVnDcqgFAsSerTfZuOcHbSvStKSJKOV6_9zXcmlRBu46AvxRluOqcc8BIFsv9nkB_E0Vh5WXsdPUnPb_cbEa0NYExwZYdmSGYiOFGwPBGh4GaO4A_vdEnhmQfm5xfjv_rHwGUvgMBOfXs7gfUhpppGNOlTMKJL6kTO42S2yiVbtLjPkwohcr-Xb7_R4qb9lzOAio95a0kgxlIOyV6Wi5IBe7Tv88zcc5ohINXJdPDxkry1sfLQ6QK_T1moArtzcX_T_SMvrMaDh48da_WakNv--XOfOoIT5Nw2p1h0bBmsketvTDZhhxvXwaPJHJR2CMaWxWHl-Gi1a1yzExk5ClbZA_fADlDjOzMNNLNxDiP-AEsNMJTowZc8wrLP__zF1eYVjX
  Warning  FailedBuildModel        35m                ingress  Failed build model due to operation error EC2: CreateSecurityGroup, https response error StatusCode: 403, RequestID: d5670497-7e92-4ab2-88e3-ef09b81854cd, api error UnauthorizedOperation: You are not authorized to perform this operation. User: arn:aws:sts::084375569056:assumed-role/ecommerce-cluster-alb-controller/1750711517954784008 is not authorized to perform: ec2:CreateSecurityGroup on resource: arn:aws:ec2:us-east-1:084375569056:vpc/vpc-097127ba3fab8eeda because no identity-based policy allows the ec2:CreateSecurityGroup action. Encoded authorization failure message: 5kng9y6Za32cfh65-Yd_ApTAGhURm5wL75Eojqq3FUmeZOzp_6Dqoqv6TOB580NFVEfyaZfTnUT4NC84HOZn8QpX98gV7eae2e0_HB4STPZBdG9wahvAvST_3jfGIHJT2UVUFxz2VGIBs0wS74g7VpbIscnEAAms4bySxpPi3HfnJztqJlbOAAuRp9w6kws3dh_k8Z55n-J1s-JUl2BkLazDLIf1fKAx-YgjkmvdStg2BaMU9d9poZmdYMX9dBnSTkHZ6AUEtNE-7bscpyXKkDEck6Nj9ncrHKr6DNVuPdnPbJe8P7ar0-wMkvID9yt4ud-aEp6yx21nvbsiV4hFJyXeB83MD9k5VIbfKnp6_fUy-6ymkWXXU1obIY5aIKf7iARQzwJ7dP3alnRatBP5GS58qMx6qED5zeLQutZUInBXCCUJ2OTLxRHWyZjosfIM-fiYmh9mXalK6h--wBwwG_MQc0QWnOAox3W6LVr1_JNYKPZEUnvPEQf6t8nvQz9S81xPZCc8RTJhdV92lnWJEdq-f2PVaEmETtjjwFtr-esymxhrm4jvHmhmqMLMlIe3dvR01jrWHBuPX3V5TBYkbch4xZmi_ThFlZ3c8TfvmHs4CjP84hlFpiNQ_6AqKiwKyRrEU_a-cIUtxA
  Warning  FailedBuildModel        35m                ingress  Failed build model due to operation error EC2: CreateSecurityGroup, https response error StatusCode: 403, RequestID: 3274b433-f602-464f-bae2-7689be4259f1, api error UnauthorizedOperation: You are not authorized to perform this operation. User: arn:aws:sts::084375569056:assumed-role/ecommerce-cluster-alb-controller/1750711517954784008 is not authorized to perform: ec2:CreateSecurityGroup on resource: arn:aws:ec2:us-east-1:084375569056:vpc/vpc-097127ba3fab8eeda because no identity-based policy allows the ec2:CreateSecurityGroup action. Encoded authorization failure message: EPBK9OZFLgAazxL-At5xssYS9JSLIRe-CluJFeWaJUcxFUolAGnqiL3eVnqFkr-CUGipH17hL8OwEuea9hyzQOBE5FLC8zZjFP_q5GwZDmiM05_eHk8jkVw9VJ0XR8OG2tICpgSp4Kflt1fQmmaRPboB1RmvcdjPaMG8MMN7PiERbwljZ5Vc9L3Mpx8NDEnUkTfIPbszWyVs3NteTo8HaafW5MKNsBcizJffUQlDO4YOjgZ2V30ZqMDJUFu9JJzxMgVEu58dX2izukGjxidgSSsdCLjKU0wy6GIGI9UozP6BZ50-w4n5n3AzkE4Gye_V2E4MxqYjt0hbQAtjjMpzkNO6RwY7RtcLKP0v0_i90CSkMe8HzZF5pmCJ52qKhZxe70QT1mnjv2nP2vV7sbA0H5M_HMMMF2t5t1adfYYLx1qtjDOQ62wlwSQ_w8SB2AJ-walUqmWrMab6GnfEpY3wAEhjksMyIETY2ZYhPiksehf5Ss2i0ZkOjsOp-CnXXSK6V8I6SwKayNelFMflHxccNbnlIiMcrdWbH5mqnY--ixGAtVaxHRYujuKn1JXTn30yl9ICynuPnM6zbqLRB-V5ZtiuSYEJqbkTWWR6MBpUmMqWCiHuI_JOsyd35kKa-lQCO8LqYVAkUhdg
  Warning  FailedBuildModel        24m (x9 over 35m)  ingress  (combined from similar events): Failed build model due to operation error EC2: CreateSecurityGroup, https response error StatusCode: 403, RequestID: 4132a86c-5ebb-4932-a650-497b6de2d689, api error UnauthorizedOperation: You are not authorized to perform this operation. User: arn:aws:sts::084375569056:assumed-role/ecommerce-cluster-alb-controller/1750711517954784008 is not authorized to perform: ec2:CreateSecurityGroup on resource: arn:aws:ec2:us-east-1:084375569056:vpc/vpc-097127ba3fab8eeda because no identity-based policy allows the ec2:CreateSecurityGroup action. Encoded authorization failure message: yAfT9OjP3Cc6uXEmm_d5Ob34gEHqcKbnijsugN1D3hcH3jqDOsfDJTDc7dz0E4zS14YHLex8x7CWuziwv2qKEmHTBIs8tA1SkXM4ndKgSOHOHxffGRCyn6tO0ZILRnEczC4KRnFOTvnxpPI6t7Zo1vVDbZbZT6D_mklQcc6qyQUaHm6zp3I69a_dF9FU1iwFx3_JDroRW8WMoM0xFco5vIeOD6lMuqvriAuLJZNP55k-aC7JqN6dTwDv6GpDp4aqyqYVeKXZ4hizyxtCPBSDkomhWDz5DZNroUvf7qvG9n1REk61RJdBdmso-iish7jjc-bskfFiFpBmtDE1kM3e_GWqy4GM2Z-euWvREGp1a9V5wdl1nSHxlbiL99MS_DqbospWgfEYfH_Rp5yJCoWggE8YtSgnHhUbNmOQqTjIVGrnec0ezQuZJ7-XrV-GZmcYTlgyvCHhfz3d3b0JUeI0Td9CVU-wQZNWp6S3IArqxztXtV8bYfZLs8Ofq8RUkLuX-3J24rg7oqLphvXcr84oTha0YdSBjceEAN091qJBGllFcEl-zSMVJwyKCKk7xH-lihGv5qPBMtI5SHMaen399NGypAKiZWE94eICxKJ3EawkquPPDtwG_UoBNdoQd3hgLsxzfgrLG8mr
  Normal   SuccessfullyReconciled  20m                ingress  Successfully reconciled
tim@Tims-MacBook-Pro stage1-infra % kubectl get service sample-app -n default
NAME         TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
sample-app   NodePort   172.20.34.232   <none>        80:30080/TCP   4h29m
tim@Tims-MacBook-Pro stage1-infra % kubectl describe service sample-app -n default
Name:                     sample-app
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 app=sample-app
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.34.232
IPs:                      172.20.34.232
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  30080/TCP
Endpoints:                10.0.1.127:80
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>
tim@Tims-MacBook-Pro stage1-infra % 

tim@Tims-MacBook-Pro stage2-k8s % aws elbv2 describe-target-groups --names k8s-default-sampleap-133ef030bd --region us-east-1 --profile terraform-admin
{
    "TargetGroups": [
        {
            "TargetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:084375569056:targetgroup/k8s-default-sampleap-133ef030bd/03c678e4f87268e6",
            "TargetGroupName": "k8s-default-sampleap-133ef030bd",
            "Protocol": "HTTP",
            "Port": 80,
            "VpcId": "vpc-097127ba3fab8eeda",
            "HealthCheckProtocol": "HTTP",
            "HealthCheckPort": "traffic-port",
            "HealthCheckEnabled": true,
            "HealthCheckIntervalSeconds": 15,
            "HealthCheckTimeoutSeconds": 5,
            "HealthyThresholdCount": 2,
            "UnhealthyThresholdCount": 2,
            "HealthCheckPath": "/",
            "Matcher": {
                "HttpCode": "200"
            },
            "LoadBalancerArns": [
                "arn:aws:elasticloadbalancing:us-east-1:084375569056:loadbalancer/app/k8s-default-sampleap-e38fe595da/9bc93d379918221a"
            ],
            "TargetType": "ip",
            "ProtocolVersion": "HTTP1",
            "IpAddressType": "ipv4"
        }
    ]
}


tim@Tims-MacBook-Pro stage2-k8s % aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:084375569056:targetgroup/k8s-default-sampleap-133ef030bd/03c678e4f87268e6 --region us-east-1 --profile terraform-admin
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "10.0.1.127",
                "Port": 80,
                "AvailabilityZone": "us-east-1a"
            },
            "HealthCheckPort": "80",
            "TargetHealth": {
                "State": "healthy"
            },
            "AdministrativeOverride": {
                "State": "no_override",
                "Reason": "AdministrativeOverride.NoOverride",
                "Description": "No override is currently active on target"
            }
        }
    ]
}


tim@Tims-MacBook-Pro stage2-k8s % aws ec2 describe-security-groups --group-ids sg-0d656f98a82abfa3b --region us-east-1 --profile terraform-admin
{
    "SecurityGroups": [
        {
            "GroupId": "sg-0d656f98a82abfa3b",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "Description": "Allow all egress",
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                }
            ],
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "ecommerce-cluster-node"
                },
                {
                    "Key": "kubernetes.io/cluster/ecommerce-cluster",
                    "Value": "owned"
                }
            ],
            "VpcId": "vpc-097127ba3fab8eeda",
            "OwnerId": "084375569056",
            "GroupName": "ecommerce-cluster-node-20250623002506915300000011",
            "Description": "EKS node shared security group",
            "IpPermissions": [
                {
                    "IpProtocol": "tcp",
                    "FromPort": 80,
                    "ToPort": 80,
                    "UserIdGroupPairs": [
                        {
                            "Description": "elbv2.k8s.aws/targetGroupBinding=shared",
                            "UserId": "084375569056",
                            "GroupId": "sg-09780ee0083e461a1"
                        }
                    ],
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 6443,
                    "ToPort": 6443,
                    "UserIdGroupPairs": [
                        {
                            "Description": "Cluster API to node 6443/tcp webhook",
                            "UserId": "084375569056",
                            "GroupId": "sg-01c944107bfe23491"
                        }
                    ],
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 9443,
                    "ToPort": 9443,
                    "UserIdGroupPairs": [
                        {
                            "Description": "Cluster API to node 9443/tcp webhook",
                            "UserId": "084375569056",
                            "GroupId": "sg-01c944107bfe23491"
                        }
                    ],
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 1025,
                    "ToPort": 65535,
                    "UserIdGroupPairs": [
                        {
                            "Description": "Node to node ingress on ephemeral ports",
                            "UserId": "084375569056",
                            "GroupId": "sg-0d656f98a82abfa3b"
                        }
                    ],
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 8443,
                    "ToPort": 8443,
                    "UserIdGroupPairs": [
                        {
                            "Description": "Cluster API to node 8443/tcp webhook",
                            "UserId": "084375569056",
                            "GroupId": "sg-01c944107bfe23491"
                        }
                    ],
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 10250,
                    "ToPort": 10250,
                    "UserIdGroupPairs": [
                        {
                            "Description": "Cluster API to node kubelets",
                            "UserId": "084375569056",
                            "GroupId": "sg-01c944107bfe23491"
                        }
                    ],
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 53,
                    "ToPort": 53,
                    "UserIdGroupPairs": [
                        {
                            "Description": "Node to node CoreDNS",
                            "UserId": "084375569056",
                            "GroupId": "sg-0d656f98a82abfa3b"
                        }
                    ],
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "udp",
                    "FromPort": 53,
                    "ToPort": 53,
                    "UserIdGroupPairs": [
                        {
                            "Description": "Node to node CoreDNS UDP",
                            "UserId": "084375569056",
                            "GroupId": "sg-0d656f98a82abfa3b"
                        }
                    ],
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 4443,
                    "ToPort": 4443,
                    "UserIdGroupPairs": [
                        {
                            "Description": "Cluster API to node 4443/tcp webhook",
                            "UserId": "084375569056",
                            "GroupId": "sg-01c944107bfe23491"
                        }
                    ],
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 443,
                    "ToPort": 443,
                    "UserIdGroupPairs": [
                        {
                            "Description": "Cluster API to node groups",
                            "UserId": "084375569056",
                            "GroupId": "sg-01c944107bfe23491"
                        }
                    ],
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                }
            ]
        }
    ]
}


tim@Tims-MacBook-Pro stage2-k8s % aws ec2 describe-security-groups --group-ids sg-09780ee0083e461a1 --region us-east-1 --profile terraform-admin
{
    "SecurityGroups": [
        {
            "GroupId": "sg-09780ee0083e461a1",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                }
            ],
            "Tags": [
                {
                    "Key": "elbv2.k8s.aws/resource",
                    "Value": "backend-sg"
                },
                {
                    "Key": "elbv2.k8s.aws/cluster",
                    "Value": "ecommerce-cluster"
                }
            ],
            "VpcId": "vpc-097127ba3fab8eeda",
            "OwnerId": "084375569056",
            "GroupName": "k8s-traffic-ecommercecluster-91d5facc2e",
            "Description": "[k8s] Shared Backend SecurityGroup for LoadBalancer",
            "IpPermissions": []
        }
    ]
}

