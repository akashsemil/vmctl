#!/bin/bash

# variables
declare HOST 				# whether a localhost or remote
declare VM_LIST 			# list of vm
declare VM_COUNT=0 			# total count of vm available
declare VM_NAME 			# selected vm name
declare VM_STATUS 			# contain status of selected vm
declare SNAPSHOT_COUNT=0 	# total count of snapshot
declare SNAPSHOT_LIST 		# list of snapshot
declare SNAPSHOT_NAME 		# selected snapshot name
declare RESULT 				# temp variable to store result of command executed

GET_VM_LIST()
{
	# function to populate vm list
	RESULT=$(ssh $HOST -C "virsh -c qemu:///system list --all --name | tr -s '\n' ' '")
	for VM in $RESULT
	do
		VM_LIST[VM_COUNT]=$VM_COUNT" "$VM
		((VM_COUNT=VM_COUNT+1))
	done
}
GET_VM_STATUS()
{
	# function to get vm status
	VM_NAME=$(echo ${VM_LIST[$RESULT]} | cut -d ' ' -f2)
	VM_STATUS=$(ssh $HOST -C "virsh -c qemu:///system domstate $VM_NAME | tr -d '\n'")
}
GET_SNAPSHOT_LIST()
{
	# function to populate snapshot list
	RESULT=$(ssh $HOST -C "virsh -c qemu:///system snapshot-list $VM_NAME --name | tr -s '\n' ' '")
	for SNAPSHOT in $RESULT
	do
		SNAPSHOT_LIST[SNAPSHOT_COUNT]=$SNAPSHOT_COUNT" "$SNAPSHOT
		((SNAPSHOT_COUNT=SNAPSHOT_COUNT+1))
	done
}
MANAGE_VM_STATE()
{
	case $(whiptail --title "VM Control: $HOST" --menu "Manage VM State: $VM_NAME : $VM_STATUS" 30 60 10 \
	"1." "PowerON" \
	"2." "Shutdown" \
	"3." "Reboot" \
	"4." "ForceOFF" 3>&1 1>&2 2>&3) in
	
	'1.')
		# PowerON VM
		RESULT=$(ssh $HOST -C "virsh -c qemu:///system start $VM_NAME")
		whiptail --title "Status" --msgbox "$RESULT" 8 60
		;;
	'2.')
		# Shutdown VM
		RESULT=$(ssh $HOST -C "virsh -c qemu:///system shutdown $VM_NAME")
		whiptail --title "Status" --msgbox "$RESULT" 8 60
		;;
	'3.')
		# Reboot VM 
		RESULT=$(ssh $HOST -C "virsh -c qemu:///system reboot $VM_NAME")
		whiptail --title "Status" --msgbox "$RESULT" 8 60
		;;
	'4.')
		# ForceOff VM
		RESULT=$(ssh $HOST -C "virsh -c qemu:///system destroy $VM_NAME")
		whiptail --title "Status" --msgbox "$RESULT" 8 60
		;;
	esac
}
MANAGE_VM_SNAPSHOT()
{	
	SNAPSHOT_COUNT=0
	SNAPSHOT_LIST=()
	GET_SNAPSHOT_LIST
	case $(whiptail --title "VM Control: $HOST" --menu "Manage Snapshot: $VM_NAME : $VM_STATUS" 30 60 10 \
	"1." "Create" \
	"2." "Restore" \
	"3." "Delete" 3>&1 1>&2 2>&3) in
	
	'1.')
		# create a snapshot
		SNAPSHOT_NAME=$(whiptail --inputbox "Enter VM Snapshot Name: " 30 60 --title "Create Snapshot: $VM_NAME : $VM_STATUS" 3>&1 1>&2 2>&3)
		if [ ! -z $SNAPSHOT_NAME ]
		then
			RESULT=$(ssh $HOST -C "virsh -c qemu:///system snapshot-create-as $VM_NAME --name $SNAPSHOT_NAME")
			whiptail --title "Status" --msgbox "$RESULT" 8 60	
		fi
		;;
	'2.')
		# restore a snapshot
		RESULT=$(whiptail --title "VM Control: $HOST" --menu "Manage Snapshot: $VM_NAME : $VM_STATUS" 30 60 10 ${SNAPSHOT_LIST[*]} 3>&1 1>&2 2>&3)
		SNAPSHOT_NAME=$(echo ${SNAPSHOT_LIST[$RESULT]} | cut -d ' ' -f2)
		RESULT=$(ssh $HOST -C "virsh -c qemu:///system snapshot-revert $VM_NAME --snapshotname $SNAPSHOT_NAME")
		whiptail --title "Status" --msgbox "The domain $VM_NAME is being restored." 8 60
		;;
	'3.')
		# delete a snapshot
		RESULT=$(whiptail --title "VM Control: $HOST" --menu "Manage Snapshot: $VM_NAME : $VM_STATUS" 30 60 10 ${SNAPSHOT_LIST[*]} 3>&1 1>&2 2>&3)
		if [ ! -z $RESULT ]
		then
			SNAPSHOT_NAME=$(echo ${SNAPSHOT_LIST[$RESULT]} | cut -d ' ' -f2)
			RESULT=$(ssh $HOST -C "virsh -c qemu:///system snapshot-delete $VM_NAME --snapshotname $SNAPSHOT_NAME")
			whiptail --title "Status" --msgbox "$RESULT" 8 60
		fi
		;;
	esac
}
MAIN()
{
	
	
	# MAIN MENU
	while true
	do
		# display list of vm and store selected vm in RESULT
		RESULT=$(whiptail --title "VM Control: $HOST" --menu "Select a VM" 30 60 10 ${VM_LIST[*]} 3>&1 1>&2 2>&3)
		if [ -z $RESULT ]
		then
			# nothing in RESULT then exit
			exit 0
		else
			# function call to get VM status
			GET_VM_STATUS
			case $(whiptail --title "VM Control: $HOST" --menu "Manage VM: $VM_NAME : $VM_STATUS" 30 60 10 \
			"1." "Manage VM State: PowerON/Shutdown/Reboot/ForceOFF" \
			"2." "Manage VM Snapshot: Create/Restore/Delete" 3>&1 1>&2 2>&3) in
			'1.')
				MANAGE_VM_STATE
				;;
			'2.')
				MANAGE_VM_SNAPSHOT
				;;
			esac
		fi
	done
}
HELP()
{
	echo "Usage: $0 (FOR MANAGING LOCAL VM ONLY)"
	echo "Usage: $0 [user@[FQDN/IP]] (FOR MANAGING REMOTE VM)"
	echo "Dependencies: [Warning]"
	echo " Machine on which this tool is running requires: whiptail & libvirt-clients"
	echo " Remote Machine on which this tool will connect to only need libvirt-clients"
	echo "Description: "
	echo " VMCTL is a TUI based tool which will help you to manage local and remote vm using ssh, virsh, whiptail."
	echo " It is preferred to use password-less authentication in order to prevent entering ssh password multiple times."
}

if [ $# -eq 0 ]
then
	HOST=localhost
	GET_VM_LIST
	MAIN
elif [ $# -eq 1 ]
then
	if [ $1 == '--help' ] || [ $1 == 'help' ]
	then
		HELP
	else
		HOST=$1
		GET_VM_LIST
		MAIN
	fi
else
	HELP
fi