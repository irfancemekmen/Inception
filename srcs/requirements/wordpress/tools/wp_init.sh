#!/bin/bash
set -e

cd /var/www/wordpress

if [ ! -f /var/www/wordpress/wp-config.php ]; then
    # Şifreler Docker secrets dosyalarından okunur (.env'de tutulmaz)
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
    WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
    WP_NORMAL_PASSWORD=$(cat /run/secrets/wp_user_password)

    wp core download --allow-root

    # MariaDB bağlantı kabul edene kadar bekle (sınırlı deneme, sonsuz döngü değil)
    for i in $(seq 30); do
        mariadb -h mariadb -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" &> /dev/null && break
        sleep 2
    done

    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost=mariadb:3306 --allow-root

    wp core install \
        --url="$DOMAIN_NAME" \
        --title="Inception 42" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" --allow-root

    wp user create \
        "$WP_NORMAL_USER" "$WP_NORMAL_EMAIL" \
        --role=author --user_pass="$WP_NORMAL_PASSWORD" --allow-root
fi

chown -R www-data:www-data /var/www/wordpress

exec php-fpm8.2 -F
