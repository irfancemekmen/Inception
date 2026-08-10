#!/bin/bash

if [ ! -f /var/www/wordpress/wp-config.php ]; then
    wp core download --allow-root

    wp config create \
        --dbname=$MYSQL_DATABASE \
        --dbuser=$MYSQL_USER \
        --dbpass=$MYSQL_PASSWORD \
        --dbhost=mariadb:3306 --allow-root

    wp core install \
        --url=iekmen.42.fr \
        --title="Inception 42" \
        --admin_user=$WP_ADMIN_USER \
        --admin_password=$WP_ADMIN_PASSWORD \
        --admin_email=$WP_ADMIN_EMAIL --allow-root

    wp user create \
        $WP_NORMAL_USER $WP_NORMAL_EMAIL \
        --role=author --user_pass=$WP_NORMAL_PASSWORD --allow-root
fi

chown -R www-data:www-data /var/www/wordpress

exec php-fpm7.4 -F
