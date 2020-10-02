# vmctl a.k.a VirtualMachineControl
TUI based bash script which will help you manage local and remote VMs.
## What does manage means here ?
This script will let you manage VM states (PowerOn/Shutdown/Reboot/ForceOff) as well as VM snapshots (Create/Restore/Delete) any local or remote VM by sshing into the base machine on which the VM is running on and passing on the corresponding virsh command.
## Requirements
0. It is recommended to use password-less authentication else you need to manually enter password everytime.
```
$ ssh-keygen # generate ssh keys
$ ssh-copy-id [USER]@[IP/FQDN] # adding key to host
```
1. whiptail must be installed on machine where this script is going to run.
2. libvirt-clients must be installed on machine where this script is going to connect to.
### Ubuntu:
```
$ sudo apt install whiptail libvirt-clients -y
```
### CentOS:
```
$ sudo yum install newt libvirt-clients -y
```
## Usage:
The script will connect to local machine and manages VM that exists on local machine.
```
$ ./vmctl.sh
```
The script will connect to remote machine and manages VM that exists on remote machine.
```
$ ./vmctl.sh semil@example.com
```
