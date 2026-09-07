# Inception – Kullanıcı Dokümantasyonu (USER_DOC.md)

Bu belge, projeyi çalıştıracak veya yönetecek bir kullanıcının / sistem yöneticisinin
ihtiyaç duyduğu temel bilgileri içerir. Teknik iç detaylar için `DEV_DOC.md` dosyasına bakın.

---

## 1. Bu yığın (stack) hangi servisleri sunar?

`make` komutu üç konteyner ayağa kaldırır:

| Servis | Görevi | Dışarıya açık mı? |
| --- | --- | --- |
| **NGINX** | HTTPS web sunucusu. Sistemin tek giriş kapısı. Port 443, yalnızca TLSv1.2 / TLSv1.3. | Evet (443) |
| **WordPress + php-fpm** | Web sitesi ve yönetim paneli. PHP kodunu çalıştırır. | Hayır (yalnızca iç ağ, 9000) |
| **MariaDB** | Tüm site verisini (yazılar, kullanıcılar, ayarlar) tutan veritabanı. | Hayır (yalnızca iç ağ, 3306) |

Konteynerler `inception_network` adlı özel köprü ağı üzerinden haberleşir. Site verisi
iki kalıcı Docker volume'unda, host makinede `/home/iekmen/data` altında saklanır:

- `/home/iekmen/data/mariadb` → veritabanı dosyaları
- `/home/iekmen/data/wordpress` → WordPress site dosyaları

---

## 2. Ön koşullar

- `docker` ve `docker compose` eklentisi kurulu bir Linux makine.
- `make`.
- Alan adının yerel IP'ye çözülmesi için `/etc/hosts` dosyasına satır:

  ```
  127.0.0.1   iekmen.42.fr
  ```

- `srcs/.env` dosyası mevcut ve doldurulmuş olmalı (repoya dahil değildir, bkz. Bölüm 5).

---

## 3. Projeyi başlatma ve durdurma

Tüm komutlar projenin kök dizininden çalıştırılır.

| Komut | Ne yapar |
| --- | --- |
| `make` veya `make all` | Host veri klasörlerini oluşturur, imajları derler, konteynerleri arka planda başlatır. |
| `make down` | Konteynerleri durdurur ve siler. **Veriler korunur.** |
| `make clean` | `down` + imajları ve volume'ları siler. |
| `make fclean` | `clean` + `/home/iekmen/data` altındaki tüm veriyi siler ve kullanılmayan Docker nesnelerini temizler. |
| `make re` | `fclean` sonrası `all`. Her şeyi sıfırdan kurar. |

> İlk `make` çalıştırması WordPress'i indirip kurduğu için birkaç dakika sürebilir.

---

## 4. Siteye ve yönetim paneline erişim

- **Web sitesi:** <https://iekmen.42.fr>
- **Yönetim paneli:** <https://iekmen.42.fr/wp-admin>

Sertifika kendinden imzalı (self-signed) olduğu için tarayıcı "Bağlantınız gizli değil"
uyarısı gösterir; bu beklenen bir durumdur, devam edin.

Yönetim paneline `srcs/.env` içindeki `WP_ADMIN_USER` / `WP_ADMIN_PASSWORD` ile giriş
yapılır. İkinci kullanıcı (`WP_NORMAL_USER`, "author" rolünde) içerik üretebilir ancak
site ayarlarını değiştiremez.

---

## 5. Kimlik bilgilerini bulma ve yönetme

Tüm kimlik bilgileri **`srcs/.env`** dosyasında tutulur. Bu dosya `.gitignore` içinde
olduğu için git deposuna dahil edilmez ve asla commit edilmemelidir.

`.env` içindeki değişkenler:

| Değişken | Açıklama |
| --- | --- |
| `DOMAIN_NAME` | Sitenin alan adı (`iekmen.42.fr`) |
| `MYSQL_DATABASE` | WordPress veritabanının adı |
| `MYSQL_USER` / `MYSQL_PASSWORD` | WordPress'in veritabanına bağlanırken kullandığı hesap |
| `MYSQL_ROOT_PASSWORD` | Veritabanı `root` şifresi |
| `WP_ADMIN_USER` / `WP_ADMIN_PASSWORD` / `WP_ADMIN_EMAIL` | WordPress yönetici hesabı (kullanıcı adı `admin` / `administrator` içeremez) |
| `WP_NORMAL_USER` / `WP_NORMAL_PASSWORD` / `WP_NORMAL_EMAIL` | Normal (author) hesap |

**Şifre değiştirme:**

- Kurulumdan önce: `.env` dosyasını düzenleyin, sonra `make re` çalıştırın (mevcut
  veritabanı verisi silinir).
- Kurulumdan sonra: değişikliği çalışan konteynerde yapın, ör.
  `docker exec -it mariadb mariadb -u root -p` veya
  `docker exec -it wordpress wp user update <kullanıcı> --user_pass=<yeni> --allow-root`.

WordPress kurulumundan sonra veritabanı bilgisi `wp-config.php` dosyasına yazılır; bu
dosya host'ta `/home/iekmen/data/wordpress/wp-config.php` yolundadır ve git'e dahil
değildir.

---

## 6. Servislerin düzgün çalıştığını doğrulama

**Konteyner durumu:**

```bash
docker ps
```

`nginx`, `wordpress` ve `mariadb` satırlarının `Up` durumda olması gerekir.

**HTTPS ve TLS sürümü:**

```bash
curl -kIv https://iekmen.42.fr
```

Yanıtta `TLSv1.2` ya da `TLSv1.3` ve `HTTP/1.1 200 OK` (veya `301` / `302`) görülmelidir.
Eski protokoller reddedilmelidir:

```bash
curl -k --tlsv1.1 --tls-max 1.1 https://iekmen.42.fr   # başarısız olmalı
```

**Veritabanı bağlantısı:**

```bash
docker exec -it mariadb mariadb -u root -p -e "SHOW DATABASES;"
```

`.env` içindeki `MYSQL_DATABASE` listede görünmelidir.

**Kalıcılık (persistence) testi:**

1. Panelden bir test yazısı yayınlayın.
2. `make down` ardından `make all`.
3. Yazı hâlâ duruyorsa volume'lar doğru çalışıyordur.

**Loglar:**

```bash
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

**Ağ izolasyonu:** MariaDB ve php-fpm host makineden erişilemez olmalıdır:

```bash
nc -zv 127.0.0.1 3306   # bağlanamamalı (Connection refused)
nc -zv 127.0.0.1 9000   # bağlanamamalı (Connection refused)
```
