#!/bin/bash
miq_hostname=$1
vmdb_private_ip=$2
ssh_login_user=$3
ssh_login_passwd=$4
db_user=$5
db_pass=$6

#set hostname
hostnamectl set-hostname  $miq_hostname

# Synchronize time
systemctl enable chronyd.service
systemctl start chronyd.service

#Restore default database configuration file
\cp /var/www/miq/vmdb/config/database.pg.yml /var/www/miq/vmdb/config/database.yml

# Fetch remote encryption key
appliance_console_cli --fetch-key=$vmdb_private_ip --sshlogin=$ssh_login_user --sshpassword=$ssh_login_passwd

#Connect to external region in database
appliance_console_cli --hostname=$vmdb_private_ip --username=$db_user --password=$db_pass --auto-failover


# Reboot 
reboot


#Configure remote database
#appliance_console_cli  --replication=$replication_type --primary-host=$private_ip --cluster-node-number=$cluster_node_number --username=$cfme_db_user --password=$cfme_db_pass

#Reset configured database
#cd /var/www/miq/vmdb
#DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rake evm:db:region -- --region=$mig_region

