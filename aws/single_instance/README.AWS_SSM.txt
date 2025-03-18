(py3) tim@Tims-MBP single_instance % aws --version

aws-cli/2.18.10 Python/3.12.6 Darwin/22.6.0 exe/x86_64
(py3) tim@Tims-MBP single_instance % curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 3917k  100 3917k    0     0  2116k      0  0:00:01  0:00:01 --:--:-- 2117k
(py3) tim@Tims-MBP single_instance % unzip sessionmanager-bundle.zip
Archive:  sessionmanager-bundle.zip
   creating: sessionmanager-bundle/
  inflating: sessionmanager-bundle/seelog.xml.template  
  inflating: sessionmanager-bundle/THIRD-PARTY  
  inflating: sessionmanager-bundle/LICENSE  
  inflating: sessionmanager-bundle/RELEASENOTES.md  
  inflating: sessionmanager-bundle/NOTICE  
  inflating: sessionmanager-bundle/install  
   creating: sessionmanager-bundle/bin/
  inflating: sessionmanager-bundle/bin/session-manager-plugin  
  inflating: sessionmanager-bundle/README.md  
 extracting: sessionmanager-bundle/VERSION  
(py3) tim@Tims-MBP single_instance % sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
Password:
Creating install directories: /usr/local/sessionmanagerplugin/bin
Creating Symlink from /usr/local/sessionmanagerplugin/bin/session-manager-plugin to /usr/local/bin/session-manager-plugin
Installation successful!
(py3) tim@Tims-MBP single_instance % session-manager-plugin --version
1.2.707.0

(py3) tim@Tims-MBP single_instance % terraform state list | grep aws_instance
module.compute.aws_instance.private-ec2
module.compute.aws_instance.public-ec2
(py3) tim@Tims-MBP single_instance % aws ssm describe-instance-information --filters "Key=InstanceIds,Values=i-0174593da2fd9d4d5"
{
    "InstanceInformationList": [
        {
            "InstanceId": "i-0174593da2fd9d4d5",
            "PingStatus": "Online",
            "LastPingDateTime": "2025-03-14T14:47:25.773000-07:00",
            "AgentVersion": "3.3.987.0",
            "IsLatestVersion": false,
            "PlatformType": "Linux",
            "PlatformName": "Ubuntu",
            "PlatformVersion": "20.04",
            "ResourceType": "EC2Instance",
            "IPAddress": "10.0.0.45",
            "ComputerName": "ip-10-0-0-45.us-west-1.compute.internal",
            "SourceId": "i-0174593da2fd9d4d5",
            "SourceType": "AWS::EC2::Instance"
        }
    ]
}
(py3) tim@Tims-MBP single_instance % aws ssm start-session --target i-0174593da2fd9d4d5

Starting session with SessionId: bluedragon-nnbtt3ro5kp3frfg8l843o7fby
$ hostname -I
10.0.0.45 
$ ss -altp
State           Recv-Q          Send-Q                     Local Address:Port                       Peer Address:Port          Process          
LISTEN          0               4096                       127.0.0.53%lo:domain                          0.0.0.0:*                              
LISTEN          0               128                              0.0.0.0:ssh                             0.0.0.0:*                              
LISTEN          0               128                                 [::]:ssh                                [::]:*                              
$ whoami
ssm-user
$ exit


Exiting session with sessionId: bluedragon-nnbtt3ro5kp3frfg8l843o7fby.

(py3) tim@Tims-MBP single_instance % terraform state list | grep aws_instance                                                    
module.compute.aws_instance.private-ec2
module.compute.aws_instance.public-ec2
(py3) tim@Tims-MBP single_instance % terraform state show module.compute.aws_instance.private-ec2 | grep 'i-'
    ami                                  = "ami-0347e16ae916f31a9"
    arn                                  = "arn:aws:ec2:us-west-1:084375569056:instance/i-0174593da2fd9d4d5"
    id                                   = "i-0174593da2fd9d4d5"
    primary_network_interface_id         = "eni-0a765ed98dd728538"
(py3) tim@Tims-MBP single_instance % aws ssm describe-instance-information --filters "Key=InstanceIds,Values=i-0174593da2fd9d4d5"
{
    "InstanceInformationList": [
        {
            "InstanceId": "i-0174593da2fd9d4d5",
            "PingStatus": "Online",
            "LastPingDateTime": "2025-03-14T14:47:25.773000-07:00",
            "AgentVersion": "3.3.987.0",
            "IsLatestVersion": false,
            "PlatformType": "Linux",
            "PlatformName": "Ubuntu",
            "PlatformVersion": "20.04",
            "ResourceType": "EC2Instance",
            "IPAddress": "10.0.0.45",
            "ComputerName": "ip-10-0-0-45.us-west-1.compute.internal",
            "SourceId": "i-0174593da2fd9d4d5",
            "SourceType": "AWS::EC2::Instance"
        }
    ]
}
(py3) tim@Tims-MBP single_instance % aws ssm start-session --target i-0174593da2fd9d4d5

Starting session with SessionId: bluedragon-bpaibi5rb4d6dyoa8vzzpsnbg8
$ whoami
ssm-user
$ ss -atlp
State           Recv-Q          Send-Q                     Local Address:Port                       Peer Address:Port          Process          
LISTEN          0               4096                       127.0.0.53%lo:domain                          0.0.0.0:*                              
LISTEN          0               128                              0.0.0.0:ssh                             0.0.0.0:*                              
LISTEN          0               128                                 [::]:ssh                                [::]:*                              
$ exit


Exiting session with sessionId: bluedragon-bpaibi5rb4d6dyoa8vzzpsnbg8.
