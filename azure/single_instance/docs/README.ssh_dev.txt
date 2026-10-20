
tim@Timothys-MacBook-Air terraform % ./azure/scripts/ssh_vm.sh dev   
+ ssh -p 22 azureuser@20.69.161.39
Warning: Permanently added '20.69.161.39' (ED25519) to the list of known hosts.
Welcome to Ubuntu 24.04.5 LTS (GNU/Linux 7.0.0-1017-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Tue Oct 20 22:10:47 UTC 2026

  System load:  0.08               Temperature:           49.9 C
  Usage of /:   13.7% of 28.02GB   Processes:             124
  Memory usage: 25%                Users logged in:       0
  Swap usage:   0%                 IPv4 address for eth0: 10.1.3.4

Expanded Security Maintenance for Applications is not enabled.

6 updates can be applied immediately.
6 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable

3 additional security updates can be applied with ESM Apps.
Learn more about enabling ESM Apps service at https://ubuntu.com/esm



The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

azureuser@public-vm-dev:~$ hostname
public-vm-dev
azureuser@public-vm-dev:~$ exit
logout
Connection to 20.69.161.39 closed.
tim@Timothys-MacBook-Air terraform % ./azure/scripts/ssh_vm.sh dev private
+ ssh azureuser@10.1.4.4 via azureuser@20.69.161.39:22
Warning: Permanently added '10.1.4.4' (ED25519) to the list of known hosts.
Welcome to Ubuntu 24.04.5 LTS (GNU/Linux 7.0.0-1017-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Tue Oct 20 22:11:11 UTC 2026

  System load:  0.04              Temperature:           49.9 C
  Usage of /:   7.7% of 28.02GB   Processes:             120
  Memory usage: 17%               Users logged in:       0
  Swap usage:   0%                IPv4 address for eth0: 10.1.4.4

Expanded Security Maintenance for Applications is not enabled.

7 updates can be applied immediately.
7 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status



The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

azureuser@private-vm-dev:~$ hostname
private-vm-dev
azureuser@private-vm-dev:~$ exit
logout
Connection to 10.1.4.4 closed.

