#!/bin/bash
#set -x


echo -e "Install MySQL repository"
yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm

# echo -e "Disable MySQL 8.0 repository"
# yum-config-manager --disable mysql80-community

# echo -e "Enable MySQL 5.7 repository"
# yum-config-manager --enable mysql57-community

echo -e "Install MySQL repository"
yum install -y mysql-community-server mysql-community-client

echo -e "Create MySQL Configuration File"
cp /etc/my.cnf /tmp/my.cnf.org
cp -p mysql_rhel.cnf.j2 /etc/my.cnf
chmod 0644 /etc/my.cnf
chown root:root /etc/my.cnf

# echo -e "Generate MySQL Server ID"
# mysql_server_id=`hostname -I | sed -e 's/ \+\([a-z0-9]\+\:\)\+[a-z0-9]\+//' | sed -e 's/ /\n/' | grep -v '^$' | tail -1 | awk -F. '{print $3 * 256 + $4}'`
# echo -e "MySQL Server ID : $mysql_server_id"

echo -e "Create /etc/init.d/mysql file"
cp -p mysql /etc/init.d/mysql
chmod 755 /etc/init.d/mysql
chown root:root /etc/init.d/mysql

echo -e "Disable selinux"
setenforce 0
cp -p selinux /etc/sysconfig/selinux

echo -e "Enable the MySQL service"
service mysqld start

# echo -e "Set new root password from default temporary password"
# mysql_root_password_temp=`awk -F': ' '$0 ~ \"temporary password\"{print $2}' /var/log/mysqld.log`
# mysql -e \"SET PASSWORD = '{{ passwd_mysql_root }}';\" --connect-expired-password -uroot -p'{{ mysql_root_password_temp.stdout }}' && touch /root/.my.password.changed