#!/bin/bash

miq_replication_type=$1
miq_private_ip=$2
miq_cluster_node_number=$3
db_user=$4
db_pass=$5
miq_db_disk=$6
miq_primary_host_ip=$7

echo `date` "== CONFIGURE VMDB [$miq_hostname] REPLICATION: START =="

function configure_master_replication() {
    # Configure database replication
    echo `date` "Task : Configure database replication : START"
    appliance_console_cli \
        --replication=$miq_replication_type \
        --primary-host=$miq_private_ip \
        --cluster-node-number=$miq_cluster_node_number \
        --username=$db_user \
        --password=$db_pass \
        --auto-failover
    echo `date` "Task : Configure database replication : COMPLETE"

    # Database replication status
    echo `date` "Task : Verify Database replication status : START"
    su - postgres -c "repmgr cluster show"
    echo `date` "Task : Verify Database replication status : COMPLETE"

    echo `date` "== CONFIGURE MASTER VMDB [$miq_private_ip] : COMPLETE =="
}


function configure_replication() {
    # Configure database replication
    echo `date` "Task : Configure database replication start : START"
    if [ "$miq_replication_type" == "standby" ];
    then
        echo `date` "Task : Standby database replication";
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
        echo `date` "Task : Primary database replication";
        appliance_console_cli \
          --replication=$miq_replication_type \
          --primary-host=$miq_primary_host_ip \
          --cluster-node-number=$miq_cluster_node_number \
          --dbdisk=$miq_db_disk \
          --username=$db_user \
          --password=$db_pass \
          --auto-failover
    fi
    echo `date` "Task : Configure database replication start : COMPLETE"
    # Database replication status
    echo `date` "Task : Verify Database replication status : START"
    su - postgres -c "repmgr cluster show"
    echo `date` "Task : Verify Database replication status : COMPLETE"

    echo `date` "== CONFIGURE VMDB [$miq_private_ip] : COMPLETE =="
}

if [ "$miq_primary_host_ip" <>  null ];
then
    echo `date` "Task : [$miq_replication_type] database replication";
    configure_replication
else
    echo `date` "Task : [$miq_replication_type] database replication";
    configure_master_replication
fi