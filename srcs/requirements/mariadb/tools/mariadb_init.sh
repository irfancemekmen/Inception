#!/bin/bash
set -e

# İlk çalıştırma: sistem tabloları ("mysql" şeması) yoksa veritabanını sıfırdan hazırla.
# Bind ile host'a bağlı volume'da Docker imaj içeriğini kopyalamadığı için
# /var/lib/mysql ilk açılışta boş olabilir; bu yüzden datadir'i burada kuruyoruz.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "MariaDB ilk kurulumu yapılıyor..."

    chown -R mysql:mysql /var/lib/mysql
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db > /dev/null

    # Veritabanını, kullanıcıyı ve şifreleri çevrimdışı (bootstrap) modda oluştur.
    # Bootstrap modu ağ soketi açmaz; "start / sleep / shutdown" hilesine gerek kalmaz.
    mysqld --user=mysql --bootstrap <<EOF
USE mysql;
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    echo "MariaDB ilk kurulumu tamamlandı."
fi

# MariaDB'yi PID 1 olarak ön planda çalıştır
exec mysqld_safe
