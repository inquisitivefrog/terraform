
tim@Timothys-MacBook-Air terraform % gcp/scripts/ssh_vm.sh prod
+ gcloud compute ssh public-vm-prod --zone us-west2-a --project bluedragon-sre-vuft1e --tunnel-through-iap
WARNING: 

To increase the performance of the tunnel, consider installing NumPy. For instructions,
please see https://cloud.google.com/iap/docs/using-tcp-forwarding#increasing_the_tcp_upload_bandwidth

Welcome to Ubuntu 24.04.5 LTS (GNU/Linux 7.0.0-1014-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Tue Oct 20 17:00:42 UTC 2026

  System load:  0.33              Processes:             121
  Usage of /:   65.1% of 8.65GB   Users logged in:       0
  Memory usage: 43%               IPv4 address for ens4: 10.0.3.2
  Swap usage:   0%


Expanded Security Maintenance for Applications is not enabled.

5 updates can be applied immediately.
5 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable

3 additional security updates can be applied with ESM Apps.
Learn more about enabling ESM Apps service at https://ubuntu.com/esm

New release '26.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.


dentaldanplateosaurus_gmail_com@public-vm-prod:~$ hostname
public-vm-prod.us-west2-a.c.bluedragon-sre-vuft1e.internal
dentaldanplateosaurus_gmail_com@public-vm-prod:~$ uptime
 17:01:40 up 28 min,  3 users,  load average: 0.13, 0.69, 0.85
dentaldanplateosaurus_gmail_com@public-vm-prod:~$ exit
logout
Connection to compute.2145279031429966160 closed.

tim@Timothys-MacBook-Air terraform % gcp/scripts/ssh_vm.sh prod private
+ ssh dentaldanplateosaurus_gmail_com@10.0.4.3 via public-vm-prod (IAP)
Welcome to Ubuntu 24.04.5 LTS (GNU/Linux 7.0.0-1014-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Tue Oct 20 17:02:07 UTC 2026

  System load:  0.12              Processes:             121
  Usage of /:   37.3% of 8.65GB   Users logged in:       0
  Memory usage: 34%               IPv4 address for ens4: 10.0.4.3
  Swap usage:   0%


Expanded Security Maintenance for Applications is not enabled.

6 updates can be applied immediately.
6 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status

New release '26.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.



The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

dentaldanplateosaurus_gmail_com@private-vm-prod:~$ uptime
 17:02:17 up 28 min,  2 users,  load average: 0.10, 0.07, 0.15
dentaldanplateosaurus_gmail_com@private-vm-prod:~$ exit
logout
Connection to 10.0.4.3 closed.

