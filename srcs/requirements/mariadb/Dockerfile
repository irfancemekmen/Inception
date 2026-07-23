FROM debian:bullseye

RUN apt-get update && apt-get install -y mariadb-server

# Yapılandırma ve betik dosyalarını kopyala
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/mariadb_init.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/mariadb_init.sh

EXPOSE 3306

# Konteyner başlatıldığında betiği çalıştır
ENTRYPOINT [ "mariadb_init.sh" ]