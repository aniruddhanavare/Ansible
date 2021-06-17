#!/bin/bash
miq_hostname=$1
miq_region=$2
miq_replication_type=$3
miq_private_ip=$4
miq_cluster_node_number=$5
db_user=$6
db_pass=$7
miq_primary_host_ip=$8
miq_ssh_user=$9
miq_ssh_passwd=${10}
miq_db_disk=${11}

echo "START ==>"
echo " USER " $miq_ssh_user >> /tmp/miq_conf_output.log
echo " PASSWORD " $miq_ssh_passwd >> /tmp/miq_conf_output.log
echo $miq_db_disk >> /tmp/miq_conf_output.log

echo "CONFIGURE MASTER VMDB ==>" >> /tmp/miq_conf_output.log

echo $miq_hostname >> /tmp/miq_conf_output.log
echo $miq_region >> /tmp/miq_conf_output.log
echo $miq_vpc_ip_range >> /tmp/miq_conf_output.log

function configure_miq_vmdb() {
    #set hostname
    hostnamectl set-hostname  $miq_hostname  >> /tmp/miq_conf_output.log

    # Synchronize time
    echo "Task : [$miq_hostname] Synchronize time : START" >> /tmp/miq_conf_output.log

    systemctl enable chronyd.service >> /tmp/miq_conf_output.log
    systemctl start chronyd.service >> /tmp/miq_conf_output.log

    echo "Task : Synchronize time : COMPLETE" >> /tmp/miq_conf_output.log

    #Restore default database configuration file
    echo "Task : [$miq_hostname]  Restore default database configuration file : START" >> /tmp/miq_conf_output.log
    \cp /var/www/miq/vmdb/config/database.pg.yml /var/www/miq/vmdb/config/database.yml >> /tmp/miq_conf_output.log
    systemctl stop evmserverd
    systemctl stop $APPLIANCE_PG_SERVICE
    systemctl disable $APPLIANCE_PG_SERVICE
    rm -f  /var/www/miq/vmdb/certs/v2_key REGION
    echo "Task : Restore default database configuration file : COMPLETE" >> /tmp/miq_conf_output.log


    # Fetch remote encryption key
    echo "Task : Fetch remote encryption key : START" >> /tmp/miq_conf_output.log

    appliance_console_cli --fetch-key=$miq_primary_host_ip --sshlogin=$miq_ssh_user --sshpassword=$miq_ssh_passwd >> /tmp/miq_conf_output.log
    echo "Fetch remote key completed" >> /tmp/miq_conf_output.log

    #Restart database service
    echo "Task :  Restart database service : START" >> /tmp/miq_conf_output.log
    systemctl enable $APPLIANCE_PG_SERVICE
    systemctl start $APPLIANCE_PG_SERVICE
    echo "Task :  Restart database service : Complete" >> /tmp/miq_conf_output.log


    #Reset configured database
    echo "Task :  [$miq_hostname]  Reset configured database : START" >> /tmp/miq_conf_output.log
    cd /var/www/miq/vmdb 
    DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rake evm:db:region -- --region=$miq_region  >> /tmp/miq_conf_output.log

    echo "Task : Reset configured database : COMPLETE" >> /tmp/miq_conf_output.log

    #Restart database service   
    echo "Task :  Restart database service : START" >> /tmp/miq_conf_output.log
    systemctl disable evmserverd
    systemctl enable $APPLIANCE_PG_SERVICE
    echo "Task :  Restart database service : Complete" >> /tmp/miq_conf_output.log



##POST STEPS

    echo "Task: Configure database replication start : START" >>/tmp/miq_conf_output.log 
    #Configure database replication
    if $miq_replication_type == 'standby'
    then
        appliance_console_cli  --replication=$miq_replication_type --primary-host=$miq_primary_host_ip --cluster-node-number=$miq_cluster_node_number --dbdisk=$miq_db_disk  --username=$db_user --password=$db_pass --standby-host=$miq_private_ip  --auto-failover >> /tmp/miq_conf_output.log
    else
        appliance_console_cli  --replication=$miq_replication_type --primary-host=$miq_primary_host_ip --cluster-node-number=$miq_cluster_node_number --dbdisk=$miq_db_disk  --username=$db_user --password=$db_pass --auto-failover >> /tmp/miq_conf_output.log
    fi
    #echo "Configure database replication finished" >>/tmp/miq_conf_output.log 

    #Database replication status
    su - postgres -c "repmgr cluster show"   >> /tmp/miq_conf_output.log


    # Reboot 
    #echo "Task : Reboot appliance : START" >> /tmp/miq_conf_output.log
    #reboot

}

function pinghost {
  echo "Check if the vmdb appliance is available "  >> /tmp/miq_conf_output.log 
  # Initialize number of attempts
  tryfortime=$1
  while [ $tryfortime -ne 0 ]; do
    # Ping supplied host
    ping -q -c 1 -W 1 "$2" > /dev/null 2>&1
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
    sleep 30s
  done
  # Network down, number of attempts exhausted, quiting
  echo "Network down, number of attempts exhausted, quiting "  >> /tmp/miq_conf_output.log 
  echo 1
}

#Run the remaining commands if the host is available 
if [ $(pinghost 20 $miq_primary_host_ip) -eq 0 ]; 
then
  echo 'VMDB appliance is available ... Continie with UI configure steps';   >> /tmp/miq_conf_output.log 
  configure_miq_vmdb
  exit;
#Give user friendly message and exit the script    
else 
  echo 'Unable to connect to host .';   >> /tmp/miq_conf_output.log
  exit;
fi
