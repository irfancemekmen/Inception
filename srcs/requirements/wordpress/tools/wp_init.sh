#!/bin/bash

# İşlemlerin doğru dizinde yapıldığından emin olalım
cd /var/www/wordpress

# Eğer wp-config.php yoksa kurulum işlemlerini başlat
if [ ! -f /var/www/wordpress/wp-config.php ]; then
    echo "WordPress çekirdek dosyaları indiriliyor..."
    wp core download --allow-root

    # CRITICAL FIX: MariaDB'nin hazır olmasını bekle
    echo "MariaDB'nin ayağa kalkması bekleniyor..."
    # Veritabanına bağlanana kadar 3 saniyede bir tekrar dener
    while ! mariadb -h mariadb -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 1;" &> /dev/null; do
        echo "MariaDB henüz hazır değil, bekleniyor..."
        sleep 3
    done
    echo "MariaDB hazır! Kuruluma devam ediliyor..."

    echo "wp-config.php oluşturuluyor..."
    wp config create \
        --dbname=$MYSQL_DATABASE \
        --dbuser=$MYSQL_USER \
        --dbpass=$MYSQL_PASSWORD \
        --dbhost=mariadb:3306 --allow-root

    echo "WordPress veritabanına kuruluyor..."
    wp core install \
        --url=iekmen.42.fr \
        --title="Inception 42" \
        --admin_user=$WP_ADMIN_USER \
        --admin_password=$WP_ADMIN_PASSWORD \
        --admin_email=$WP_ADMIN_EMAIL --allow-root

    echo "Normal kullanıcı oluşturuluyor..."
    wp user create \
        $WP_NORMAL_USER $WP_NORMAL_EMAIL \
        --role=author --user_pass=$WP_NORMAL_PASSWORD --allow-root
        
    echo "WordPress kurulumu tamamlandı!"
else
    echo "WordPress zaten kurulu."
fi

# Dosya izinlerini düzelt
chown -R www-data:www-data /var/www/wordpress

# PHP-FPM'i ön planda çalıştır
echo "PHP-FPM başlatılıyor..."
exec php-fpm7.4 -F