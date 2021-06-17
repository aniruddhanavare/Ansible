#!/bin/bash
miq_hostname=$1
miq_region=$2
miq_vpc_ip_range=$3
miq_replication_type=$4
miq_private_ip=$5
miq_cluster_node_number=$6
db_user=$7
db_pass=$8
echo "CONFIGURE MASTER VMDB ==>"

echo $miq_hostname >> /tmp/miq_conf_output.log
echo $miq_region >> /tmp/miq_conf_output.log
echo $miq_vpc_ip_range >> /tmp/miq_conf_output.log

#set hostname
hostnamectl set-hostname  $miq_hostname  >> /tmp/miq_conf_output.log

# Synchronize time
echo "Task : [$miq_hostname] Synchronize time : START" >> /tmp/miq_conf_output.log

systemctl enable chronyd.service >> /tmp/miq_conf_output.log
systemctl start chronyd.service >> /tmp/miq_conf_output.log

echo "Task : Synchronize time : COMPLETE" >> /tmp/miq_conf_output.log

#Restore default database configuration file
echo "Task : [$miq_hostname]  Restore default database configuration file : START" >> /tmp/miq_conf_output.log
systemctl stop evmserverd >> /tmp/miq_conf_output.log
\cp /var/www/miq/vmdb/config/database.pg.yml /var/www/miq/vmdb/config/database.yml >> /tmp/miq_conf_output.log
systemctl restart $APPLIANCE_PG_SERVICE >> /tmp/miq_conf_output.log
su - postgres -c "dropdb  -U root  vmdb_production --if-exists" >> /tmp/miq_conf_output.log

echo "Task : Restore default database configuration file : COMPLETE" >> /tmp/miq_conf_output.log

#Reset configured database
echo "Task :  [$miq_hostname]  Reset configured database : START" >> /tmp/miq_conf_output.log
cd /var/www/miq/vmdb 
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rake evm:db:region -- --region=$miq_region  >> /tmp/miq_conf_output.log

echo "Reset configured database : COMPLETE" >> /tmp/miq_conf_output.log
#Disable database server
echo "Task : Disable database server : START" >> /tmp/miq_conf_output.log
systemctl disable evmserverd
echo "Disable database server : COMPLETE" >> /tmp/miq_conf_output.log


#update pg_hba_config
echo "Task: update pg_hba_config start : START" >>/tmp/miq_conf_output.log 

PG_HBA_CONF_FILE=/var/lib/pgsql/data/pg_hba.conf
ssl_string="host all all $miq_vpc_ip_range  md5"
nossl_string="hostnossl all all $miq_vpc_ip_range md5"
grep -qF -- "$ssl_string" "$PG_HBA_CONF_FILE" || echo "$ssl_string" >> "$PG_HBA_CONF_FILE"
grep -qF -- "$nossl_string" "$PG_HBA_CONF_FILE" || echo "$nossl_string" >> "$PG_HBA_CONF_FILE"


configure_master_vmdb.sh
##POST STEPS

echo "Task: Configure database replication start : START" >>/tmp/miq_conf_output.log 
#Configure database replication
appliance_console_cli  --replication=$miq_replication_type --primary-host=$miq_private_ip --cluster-node-number=$miq_cluster_node_number  --username=$db_user --password=$db_pass  >> /tmp/miq_conf_output.log
echo "Configure database replication finished" >>/tmp/miq_conf_output.log 

#Database replication status
su - postgres -c "repmgr cluster show"   >> /tmp/miq_conf_output.log


# Reboot 
#echo "Task : Reboot appliance : START" >> /tmp/miq_conf_output.log
#reboot
