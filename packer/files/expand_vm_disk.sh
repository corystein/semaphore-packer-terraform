#!/bin/sh

#==============================================================================
#title            : expand_vm_disk.sh
#description      : This script will install PTFE
#author			  : Cory Stein
#date             : 12/06/2018
#version          : 0.1
#usage            : ./expand_vm_disk.sh
#notes            : Script requires Unix shell
#ref              :
#                 : https://help.replicated.com/docs/native/customer-installations/automating/
#==============================================================================

echo "Executing [$0]..."

# Stop script on any error
#set -e

# set device to expand
device=/dev/sda

echo "Resizing disk [$device]..."

fdisk $device <<EOF
d
2
n
p
2


w
EOF


echo "Rebooting to finish install"
reboot

# run after reboot
#xfs_growfs -d /dev/sda2

echo "Executing [$0] complete"