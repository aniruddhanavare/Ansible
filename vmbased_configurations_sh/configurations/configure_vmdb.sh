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

echo `date` "== CONFIGURE VMDB [$miq_hostname] : START =="

echo `date` "Hostname: $miq_hostname"
echo `date` "Region: $miq_region"

function configure_miq_vmdb() {
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
    systemctl stop evmserverd
    systemctl stop $APPLIANCE_PG_SERVICE
    systemctl disable $APPLIANCE_PG_SERVICE
    rm -f  /var/www/miq/vmdb/certs/v2_key REGION
    echo `date` "Task : Restore default database configuration file : COMPLETE"

    # Fetch remote encryption key
    echo `date` "Task : Fetch remote encryption key : START"
    appliance_console_cli \
      --fetch-key=$miq_primary_host_ip \
      --sshlogin=$miq_ssh_user \
      --sshpassword=$miq_ssh_passwd
    echo `date` "Task : Fetch remote encryption key : COMPLETE"

    # Restart database service
    echo `date` "Task : Restart database service : START"
    systemctl enable $APPLIANCE_PG_SERVICE
    systemctl start $APPLIANCE_PG_SERVICE
    echo `date` "Task : Restart database service : COMPLETE"

    # Reset configured database
    echo `date` "Task : Reset configured database : START"
    cd /var/www/miq/vmdb 
    DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rake evm:db:region -- --region=$miq_region
    echo `date` "Task : Reset configured database : COMPLETE"

    # Restart database service
    echo `date` "Task : Restart database service : START"
    systemctl disable evmserverd
    systemctl enable $APPLIANCE_PG_SERVICE
    echo `date` "Task : Restart database service : COMPLETE"

    # Configure database replication
    echo `date` "Task: Configure database replication start : START"
    if [ "$miq_replication_type" == "standby" ];
    then
        echo `date` "Task: standby database replication";
        appliance_console_cli \
          --replication=$miq_replication_type \
          --primary-host=$miq_primary_host_ip \
          --cluster-node-number=$miq_cluster_node_number \
          --dbdisk=$miq_db_disk \
          --username=$db_user \
          --password=$db_pass \
          --standby-host=$miq_private_ip \
          --auto-failover
    else
        echo `date` "Task: primary database replication";
        appliance_console_cli \
          --replication=$miq_replication_type \
          --primary-host=$miq_primary_host_ip \
          --cluster-node-number=$miq_cluster_node_number \
          --dbdisk=$miq_db_disk \
          --username=$db_user \
          --password=$db_pass \
          --auto-failover
    fi
    echo `date` "Task: Configure database replication start : COMPLETE"

    # Database replication status
    echo `date` "Task: Verify Database replication status : START"
    su - postgres -c "repmgr cluster show"
    echo `date` "Task: Verify Database replication status : COMPLETE"
}

function pinghost {
  echo "Check if the $2 is available "
  # Initialize number of attempts
  tryfortime=$1
  while [ $tryfortime -ne 0 ]; do
    # Ping supplied host
    ping -q -c 1 -W 1 "$2" > /dev/null 2>&1
    # Check return code
    if [ $? -eq 0 ]; then
      echo "Success, we can exit with the right return code "
      return 0
    fi
    # Network down, decrement counter and try again
    let tryfortime-=1
    echo "Sleep for 30 seconds "
    sleep 30s
  done
  echo "Network down, number of attempts exhausted, quiting "
  return 1
}

#Run the remaining commands if the host is available 
pinghost 20 $miq_primary_host_ip
pinghost_return_code=$?
if [ "$pinghost_return_code" -eq "0" ];
then
  echo "VMDB appliance $miq_primary_host_ip is available ... Continue with configuration steps";
  configure_miq_vmdb
  echo `date` "== CONFIGURE VMDB [$miq_hostname] : COMPLETE =="
  exit;
else 
  echo "Unable to connect to VMDB appliance $miq_primary_host_ip";
  echo `date` "== CONFIGURE VMDB [$miq_hostname] : ABORTED ==";
  exit;
fi
