#!/bin/bash
miq_hostname=$1
vmdb_private_ip=$2
ssh_login_user=$3
ssh_login_passwd=$4
db_user=$5
db_pass=$6

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
    --fetch-key=$vmdb_private_ip \
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

 # Start evm failover monitor
  echo `date` "Task : Start evm failover monitor : START"
  systemctl start evm-failover-monitor.service
  echo `date` "Task : Start evm failover monitor : COMPLETE"

}


function pinghost {
  echo "Check if the $2 is available " >> /tmp/miq_conf_output.log
  # Initialize number of attempts
  tryfortime=$1
  while [ $tryfortime -ne 0 ]; do
    # Ping supplied host
    ping -q -c 1 -W 1 "$2" > /dev/null 2>&1
    # Check return code
    if [ $? -eq 0 ]; then
      echo "Success, we can exit with the right return code " >> /tmp/miq_conf_output.log
      echo 0
      return
    fi
    # Network down, decrement counter and try again
    let tryfortime-=1
    echo "Sleep for one minute " >> /tmp/miq_conf_output.log
    sleep 1m
  done
  echo "Network down, number of attempts exhausted, quiting " >> /tmp/miq_conf_output.log
  echo 1
}

#Run the remaining commands if the host is available 
if [ $(pinghost 20 $vmdb_private_ip) -eq 0 ]; 
then
  echo "VMDB appliance $vmdb_private_ip is available ... Continue with configuration steps";
  configure_miq_ui
  echo `date` "== CONFIGURE UI APPLIANCE [$miq_hostname] : COMPLETE =="
else 
  echo "Unable to connect to VMDB appliance $vmdb_private_ip";
  echo `date` "== CONFIGURE UI APPLIANCE [$miq_hostname] : ABORTED ==";
  exit;
fi




