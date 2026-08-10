FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    curl \
    mariadb-client

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

COPY tools/wp_init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp_init.sh

RUN mkdir -p /run/php

EXPOSE 9000

WORKDIR /var/www/wordpress

ENTRYPOINT [ "wp_init.sh" ]
