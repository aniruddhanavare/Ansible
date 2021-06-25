#!/bin/bash
miq_hostname=$1
miq_replication_type=$2
miq_private_ip=$3
miq_cluster_node_number=$4
db_user=$5
db_pass=$6
miq_primary_host_ip=$7
miq_db_disk=$8

echo `date` "== CONFIGURE VMDB [$miq_hostname] REPLICATION: START =="

replication_args=()
replication_args+=( '--replication='$miq_replication_type )
replication_args+=( '--cluster-node-number='$miq_cluster_node_number )

if [ "$miq_db_disk" <>  null ];   #standby and worker
then
    replication_args+=( '--dbdisk='$miq_db_disk )
fi

replication_args+=( '--primary-host='$miq_primary_host_ip )
replication_args+=( '--username='$db_user)
replication_args+=( '--password='$db_pass )

if [ "$miq_replication_type" == "standby" ];  #standby
then
    replication_args+=( '--standby-host='$miq_private_ip )
fi
replication_args+=( '--auto-failover' )

appliance_console_cli "${replication_args[@]}" 
echo `date` "Task: Configure database replication start : COMPLETE"

# Database replication status
echo `date` "Task: Verify Database replication status : START"
su - postgres -c "repmgr cluster show"
echo `date` "Task: Verify Database replication status : COMPLETE"

echo `date` "== CONFIGURE VMDB [$miq_hostname] REPLICATION: COMPLETE =="
