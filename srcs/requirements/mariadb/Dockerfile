FROM	debian:bookworm-slim

# Gerekli paketleri kur ve önbelliği temizle
RUN	apt-get update && apt-get install -y \
	mariadb-server \
	&& rm -rf /var/lib/apt/lists/*

# MariaDB'nin dışarıdan (Nginx/WordPress) bağlantı kabul etmesi için konfigürasyonu güncelle
RUN	sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

RUN	mkdir -p /var/run/mysqld && \
	chown -m 755 /var/run/mysqld && \
	chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

EXPOSE	3306

#MariaDB güvenli modda başlatılır
CMD	["mysqld_safe"]
