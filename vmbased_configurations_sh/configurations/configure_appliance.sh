#!/bin/bash
miq_hostname=$1
vmdb_private_ip=$2
ssh_login_user=$3
ssh_login_passwd=$4
db_user=$5
db_pass=$6


echo "CONFIGURE UI APPLIANCE ==>"

echo $miq_hostname >> /tmp/miq_conf_output.log
echo $vmdb_private_ip >> /tmp/miq_conf_output.log
echo $ssh_login_user >> /tmp/miq_conf_output.log
echo $ssh_login_passwd >> /tmp/miq_conf_output.log
echo $db_user >> /tmp/miq_conf_output.log
echo $db_pass >> /tmp/miq_conf_output.log

function configure_miq_ui() {
  #set hostname
  hostnamectl set-hostname  $miq_hostname

  # Synchronize time
  systemctl enable chronyd.service
  systemctl start chronyd.service

  #Restore default database configuration file
  \cp /var/www/miq/vmdb/config/database.pg.yml /var/www/miq/vmdb/config/database.yml >> /tmp/miq_conf_output.log
  echo  "Restore defaul db completed" >> /tmp/miq_conf_output.log


  # Fetch remote encryption key
  appliance_console_cli --fetch-key=$vmdb_private_ip --sshlogin=$ssh_login_user --sshpassword=$ssh_login_passwd >> /tmp/miq_conf_output.log
  echo "Cert Key"
  cat /var/www/miq/vmdb/certs/v2_key >> /tmp/miq_conf_output.log
  echo "Fetch remote key completed" >> /tmp/miq_conf_output.log

  #Connect to external region in database
  appliance_console_cli --hostname=$vmdb_private_ip --username=$db_user --password=$db_pass  >> /tmp/miq_conf_output.log
  echo "Connect to external region in database completed" >> /tmp/miq_conf_output.log

  # Reboot 
  #echo "Root appliance" >> /tmp/miq_conf_output.log
  #reboot
}


function pinghost {
  echo "Check if the vmdb appliance is available "  >> /tmp/miq_conf_output.log 
  # Initialize number of attempts
  tryfortime=$1
  while [ $tryfortime -ne 0 ]; do
    # Ping supplied host
    date  >> /tmp/miq_conf_output.log 
    echo "Ping vmdb VM"  $2 >> /tmp/miq_conf_output.log 
    ping -q -c 1 -W 1 "$2" >> /tmp/miq_conf_output.log 

    # Check return code
    if [ $? -eq 0 ]; then
      # Success, we can exit with the right return code
      echo "Success, we can exit with the right return code "  >> /tmp/miq_conf_output.log 
      echo 0
      return
    fi
    # Network down, decrement counter and try again
    let tryfortime-=1
    # Sleep for one second
    echo "Sleep for one second "  >> /tmp/miq_conf_output.log 
    sleep 1m
  done
  # Network down, number of attempts exhausted, quiting
  echo "Network down, number of attempts exhausted, quiting "  >> /tmp/miq_conf_output.log 
  echo 1
}

#Run the remaining commands if the host is available 
if [ $(pinghost 20 $vmdb_private_ip) -eq 0 ]; 
then
  echo 'VMDB appliance is available ... Continie with UI configure steps';   >> /tmp/miq_conf_output.log 
  configure_miq_ui
#Give user friendly message and exit the script    
else 
  echo 'Unable to connect to host .';   >> /tmp/miq_conf_output.log
  exit;
fi




