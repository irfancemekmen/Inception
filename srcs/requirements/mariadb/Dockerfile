FROM debian:bullseye

RUN apt-get update && apt-get install -y mariadb-server

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/mariadb_init.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/mariadb_init.sh

EXPOSE 3306

ENTRYPOINT [ "mariadb_init.sh" ]
