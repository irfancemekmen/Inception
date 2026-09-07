#!/bin/bash
set -e

# Şifreler Docker secrets dosyalarından okunur (.env'de tutulmaz)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# 1) Sistem tabloları ("mysql" şeması) yoksa veri dizinini sıfırdan kur.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "MariaDB veri dizini oluşturuluyor..."
    chown -R mysql:mysql /var/lib/mysql
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db > /dev/null
fi

# 2) Proje veritabanı yoksa; veritabanını, kullanıcıyı ve şifreleri çevrimdışı
#    (bootstrap) modda oluştur. Bu blok, eski/yarım bir veri dizinini de onarır.
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Veritabanı ve kullanıcı oluşturuluyor..."
    chown -R mysql:mysql /var/lib/mysql
    mysqld --user=mysql --bootstrap <<EOF
USE mysql;
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
    echo "MariaDB kurulumu tamamlandı."
fi

# Soket dizini (her açılışta garanti et)
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# MariaDB'yi PID 1 olarak ön planda çalıştır
exec mysqld_safe
