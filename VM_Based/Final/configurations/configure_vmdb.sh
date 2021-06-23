#!/bin/bash
miq_hostname=$1
miq_region=$2
miq_replication_type=$3
miq_private_ip=$4
miq_cluster_node_number=$5
db_user=$6
db_pass=$7
encryption_ip=$8
miq_ssh_user=$9
miq_ssh_passwd=${10}
miq_db_disk=${11}

echo `date` "== CONFIGURE VMDB [$miq_hostname] : START =="

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
      --fetch-key=$encryption_ip \
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

    #reboot
    echo `date` "== VMDB [$miq_hostname] : Restarting... =="
    reboot
}

configure_miq_vmdb