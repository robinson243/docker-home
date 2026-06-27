#!/bin/bash

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials)

until mysqladmin ping -h mariadb --silent; do
    sleep 1
done

if [ ! -d "/var/www/html/wp-admin" ]; then

    wp core download --allow-root --path=/var/www/html

    wp config create \
        --allow-root \
        --path=/var/www/html \
        --dbname=$DB_NAME \
        --dbuser=$DB_USER \
        --dbpass=$DB_PASSWORD \
        --dbhost=mariadb

    wp core install \
        --allow-root \
        --path=/var/www/html \
        --url=$WP_URL \
        --title=$WP_TITLE \
        --admin_user=$WP_ADMIN \
        --admin_password=$WP_ADMIN_PASSWORD \
        --admin_email=$WP_ADMIN_EMAIL \
        --skip-email

fi

exec php-fpm7.4 -F