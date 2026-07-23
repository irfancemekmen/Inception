#!/bin/bash

# MariaDB servisini geçici olarak başlat
service mariadb start
sleep 5

# Çevre değişkenlerinden bilgileri alarak veritabanı ve kullanıcıları oluştur
mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
mysql -e "CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
mysql -e "FLUSH PRIVILEGES;"

# Geçici servisi durdur
mysqladmin -u root -p$MYSQL_ROOT_PASSWORD shutdown

# MariaDB'yi PID 1 olacak şekilde ön planda (foreground) başlat
exec mysqld_safe