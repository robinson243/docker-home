#!/bin/bash

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
    echo "ERROR: DB_NAME ou DB_USER non défini"
    exit 1
fi

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

mysqld --user=mysql --skip-networking &

until mysqladmin ping --silent 2>/dev/null; do sleep 1; done

mysql -u root -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -u root -e "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';"
mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'%';"
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';"
mysql -u root -p"$DB_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

mysqladmin -u root -p"$DB_ROOT_PASSWORD" shutdown

exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0