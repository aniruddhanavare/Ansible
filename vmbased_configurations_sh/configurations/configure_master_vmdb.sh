#!/bin/bash
miq_hostname=$1
miq_region=$2
miq_vpc_ip_range=$3
miq_replication_type=$4
miq_private_ip=$5
miq_cluster_node_number=$6
db_user=$7
db_pass=$8

echo `date` "== CONFIGURE MASTER VMDB [$miq_hostname] : START =="

echo `date` "Hostname: $miq_hostname"
echo `date` "Region: $miq_region"
echo `date` "IP Range: $miq_vpc_ip_range"

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
systemctl stop evmserverd
\cp /var/www/miq/vmdb/config/database.pg.yml /var/www/miq/vmdb/config/database.yml
systemctl restart $APPLIANCE_PG_SERVICE
su - postgres -c "dropdb  -U root  vmdb_production --if-exists"
echo `date` "Task : Restore default database configuration file : COMPLETE"

# Reset configured database
echo `date` "Task : Reset configured database : START"
cd /var/www/miq/vmdb 
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rake evm:db:region -- --region=$miq_region
echo `date` "Task : Reset configured database : COMPLETE"

# Disable database server
echo `date` "Task : Disable database server : START"
systemctl disable evmserverd
echo `date` "Task : Disable database server : COMPLETE"


# Update pg_hba_config
echo `date` "Task: Update pg_hba_config : START"
PG_HBA_CONF_FILE=/var/lib/pgsql/data/pg_hba.conf
ssl_string="host all all $miq_vpc_ip_range  md5"
nossl_string="hostnossl all all $miq_vpc_ip_range md5"
grep -qF -- "$ssl_string" "$PG_HBA_CONF_FILE" || echo "$ssl_string" >> "$PG_HBA_CONF_FILE"
grep -qF -- "$nossl_string" "$PG_HBA_CONF_FILE" || echo "$nossl_string" >> "$PG_HBA_CONF_FILE"
echo `date` "Task: Update pg_hba_config : COMPLETE"

# Configure database replication
echo `date` "Task: Configure database replication : START"
appliance_console_cli \
    --replication=$miq_replication_type \
    --primary-host=$miq_private_ip \
    --cluster-node-number=$miq_cluster_node_number \
    --username=$db_user \
    --password=$db_pass \
    --auto-failover
echo $?
reboot
echo `date` "Task: Configure database replication : COMPLETE"

# Database replication status
echo `date` "Task: Verify Database replication status : START"
su - postgres -c "repmgr cluster show"
echo `date` "Task: Verify Database replication status : COMPLETE"

echo `date` "== CONFIGURE MASTER VMDB [$miq_hostname] : COMPLETE =="
