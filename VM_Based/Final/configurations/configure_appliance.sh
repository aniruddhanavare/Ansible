#!/bin/bash
miq_hostname=$1
vmdb_private_ip=$2
ssh_login_user=$3
ssh_login_passwd=$4
db_user=$5
db_pass=$6
encryption_ip=$7

echo `date` "== CONFIGURE UI APPLIANCE [$miq_hostname] : START =="

echo `date` "Hostname: $miq_hostname"
echo `date` "VMDB Private IP: $vmdb_private_ip"

function configure_miq_ui() {
  # Set hostname
  echo `date` "Task : Set hostname : START"
  hostnamectl set-hostname  $miq_hostname
  echo `date` "Task : Set hostname : COMPLETE"

  # Synchronize time
  echo `date` "Task : Synchronize time : START"
  systemctl enable chronyd.service
  systemctl start chronyd.service
  echo `date` "Task : Synchronize time : COMPLETE"

  # Restore default database configuration file
  echo `date` "Task : Restore default database configuration file : START"
  \cp /var/www/miq/vmdb/config/database.pg.yml /var/www/miq/vmdb/config/database.yml
  echo `date` "Task : Restore default database configuration file : COMPLETE"

  # Fetch remote encryption key
  echo `date` "Task : Fetch remote encryption key : START"
  appliance_console_cli \
    --fetch-key=$encryption_ip \
    --sshlogin=$ssh_login_user \
    --sshpassword=$ssh_login_passwd
  echo `date` "Task : Fetch remote encryption key : COMPLETE"

  # Connect to external region in database
  echo `date` "Task : Connect to external region in database : START"
  appliance_console_cli \
    --hostname=$vmdb_private_ip \
    --username=$db_user \
    --password=$db_pass
  echo `date` "Task : Connect to external region in database : COMPLETE"

  #reboot
  echo `date` "== UI APPLIANCE [$miq_hostname] : Restarting... =="
  reboot
}

configure_miq_ui
