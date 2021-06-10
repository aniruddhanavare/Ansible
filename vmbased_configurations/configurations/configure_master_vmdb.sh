#!/bin/bash
miq_hostname=$1
mig_region=$2
mig_vpc_ip_range=$3


#set hostname
hostnamectl set-hostname  $miq_hostname

# Synchronize time
systemctl enable chronyd.service
systemctl start chronyd.service

#Restore default database configuration file
systemctl stop evmserverd
\cp /var/www/miq/vmdb/config/database.pg.yml /var/www/miq/vmdb/config/database.yml
systemctl restart $APPLIANCE_PG_SERVICE
su - postgres -c "dropdb  -U root  vmdb_production --if-exists"

#Reset configured database
cd /var/www/miq/vmdb
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rake evm:db:region -- --region=$mig_region


#Disable database server
#systemctl disable evmserverd

#update pg_hba_config
PG_BHA_CONF_FILE=/var/lib/pgsql/data/pg_hba.conf
ssl_string= "host all all $mig_vpc_ip_range  md5"
nossl_string= "hostnossl all all $mig_vpc_ip_range md5"
if  grep -q "$ssl_string" "$PG_BHA_CONF_FILE" ; then
         echo 'the string exists' ; 
else
         echo 'the string does not exist' ; 
         echo $ssl_string >> $PG_BHA_CONF_FILE
fi

if  grep -q "$nossl_string" "$PG_BHA_CONF_FILE" ; then
         echo 'the string exists' ; 
else
         echo 'the string does not exist' ; 
         echo $nossl_string >> $PG_BHA_CONF_FILE
fi

# Reboot 
reboot

