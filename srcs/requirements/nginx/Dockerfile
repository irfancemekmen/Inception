# Sondan bir önceki kararlı Debian sürümü
FROM debian:bullseye

# Nginx ve SSL sertifakası üretmek için OpenSSL kurulumu
RUN apt-get update && apt-get install -y nginx openssl

# SSL sertifikalarının tutulacağı dizini oluştur
RUN mkdir -p /etc/nginx/ssl

# Kendinden imzalı (self-signed) SSL sertifikası üret
RUN openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt -keyout /etc/nginx/ssl/inception.key -subj "/C=TR/ST=Kocaeli/L=Kocaeli/O=42/OU=42/CN=iekmen.42.fr/UID=iekmen"

# Yazdığımız Nginx konfigürasyon dosyasını konteynere kopyala
COPY conf/nginx.conf /etc/nginx/nginx.conf

# 443 portunu dışarıya aç
EXPOSE 443

# Nginx'i arka planda (daemon) değil, ön planda çalıştır (PID 1 kuralı için)
CMD [ "nginx", "-g", "daemon off;" ]