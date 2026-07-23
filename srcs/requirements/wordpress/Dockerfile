FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    curl \
    mariadb-client \

# wp-cli aracını indir (WordPress'i komut satırından kurmak için)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# PHP-FPM ayarı: 9000 portunu dinlemesini sağla
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

COPY tools/wp_init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp_init.sh

# PHP-FPM soketi için dizin oluştur
RUN mkdir -p /run/php

EXPOSE 9000

# Çalışma dizini olarak WordPress dosylarının duracağı yeri seç
WORKDIR /var/www/wordpress

ENTRYPOINT [ "wp_init.sh" ]