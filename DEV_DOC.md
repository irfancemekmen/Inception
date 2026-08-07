> ### Docker Nedir?
Docker, yazılım uygulamalarını ve onların çalışması için gereken tüm kütüphane, bağımlılık ve ayarları "konteyner" (container) adı verilen standart ve izole edilmiş paketler içine koyarak çalıştıran açık kaynaklı bir platformdur.

Tıpkı uluslararası ticarette kullanılan gemi konteynerleri gibi düşünebilirsiniz: İçinde araba, muz veya elektronik eşya olması fark etmez. Konteynerin boyutu ve şekli standarttır; her gemiye, trene veya tıra sorunsuzca yüklenebilir. Docker da yazılımınız için aynı standardizasyonu sağlar.

> ### Sanal Makine (VM) vs. Konteyner (Docker)
- Sanal Makineler (VM): Donanımı sanallaştırır. Sunucudaki her uygulamanın altına koca bir "Misafir İşletim Sistemi" (Guest OS - örn. tam bir Ubuntu veya Windows) kurmanız gerekir. Bu yapı GB'larca RAM, CPU ve disk alanı tüketir. Başlatılması dakikalar sürer.
- Docker (Konteyner): İşletim Sistemini sanallaştırır. Konteynerler, altlarındaki ana makinenin (Host OS) işletim sistemi çekirdeğini (Kernel) ortaklaşa kullanır. İçlerinde sadece uygulamanın çalışması için gereken kodlar ve kütüphaneler vardır. Bu sayede megabaytlar seviyesinde küçüktürler ve saniyeler (hatta milisaniyeler) içinde başlarlar.

> ### Temel Kavramlar
- Dockerfile: Uygulamanızın nasıl bir ortama ihtiyacı olduğunu yazdığınız yapılandırma dosyasıdır. (Örn: "Ubuntu tabanını al, Python kur, şu kodları kopyala ve 8080 portunu aç"). Örnek: Yemek tarifi kitabı.
- Docker Image: Dockerfile'daki talimatların derlenmiş, dondurulmuş ve paketlenmiş halidir. Sadece okunabilir (read-only) formattadır. Örnek: Yemek tarifinin pişirilip dondurulmuş hali.
- Docker Container: Bir Image'ın hafızaya alınıp çalıştırılmış halidir. Aynı Image'ı kullanarak yüzlerce bağımsız Container ayağa kaldırabilirsiniz. Örnek: Dondurulmuş yemeğin mikrodalgada ısıtılıp masaya konmuş hali.
- Docker Engine: Arka planda çalışan; konteynerleri oluşturan, başlatan, durduran ve yöneten asıl arka plan hizmetidir (daemon). Örnek: Aşçı.
- Docker Registry: Image'ların depolandığı ve paylaşıldığı yerdir. En bilineni Docker Hub'dır. Başkalarının hazırladığı (örn: hazır bir PostgreSQL veri tabanı) Image'ları buradan indirebilirsiniz. Örnek: Süpermarket.

> ### İşin Detayı
Docker aslında sıfırdan bir sanallaştırma teknolojisi icat etmemiştir. Uzun yıllardır var olan Linux çekirdek (Kernel) özelliklerini alıp, geliştiricilerin kolayca kullanabileceği harika bir araç haline getirmiştir. Konteynerlerin bu kadar hafif ve izole olmasını sağlayan iki temel teknoloji vardır:
- Namespaces (İzolasyon): Bir konteynerin, ana makinedeki diğer işlemlerden tamamen habersiz ve yalıtılmış olmasını sağlar. Konteyner; kendi ağ arabirimini, kendi süreç ağacını (process tree) ve kendi disk alanını görüyormuş gibi hisseder.
- Cgroups (Control Groups - Kaynak Yönetimi): Hangi konteynerin donanımın ne kadarını (yüzde kaç CPU, kaç MB RAM) kullanabileceğini sınırlar. Böylece bir konteynerde oluşan bir bellek sızıntısı (memory leak) tüm sunucuyu kilitleyemez.

> ### Docker Compose Nedir?
Docker Compose, birden fazla Docker konteynerini tek bir yapılandırma dosyası üzerinden tanımlamanızı, birbirine bağlamanızı ve tek bir komutla topluca yönetmenizi sağlayan resmi bir araçtır.

> ### Docker Compose Nasıl Çalışır?
Her şey projenizin ana dizinine oluşturacağınız docker-compose.yml (YAML formatında) dosyasıyla başlar. Bu dosya, sisteminizin tüm mimarisini bir metin belgesi olarak ("Infrastructure as Code") tanımlar.

>### docker-compose.yml

Bu dosya, projenin "mimari planı"dır. Üç farklı konteynerin (MariaDB, WordPress, NGINX) birbirine nasıl bağlanacağını, hangi ağda konuşacağını ve verilerini nereye kaydedeceğini Docker'a söyler.

#### Temel Çatı: Versiyon ve Servisler

```bash
YAML

version: '3.8'
```

- `version:` Compose dosyasının hangi "sözdizimi" (syntax) kurallarına göre okunduğunu belirtir. İngilizcenin farklı lehçeleri gibi düşünebilirsin.

#### MariaDB Servisi (Veritabanı)

`MariaDB` veritabanı yönetim sistemidir. MySQL'in doğrudan bir çatalıdır(fork).

Bu projede WordPress kullanıyorsun. WordPress bir web sitesinin `beyni`(PHP kodları) ve `gövdesi`(HTML/CSS) ise, MariaDB o web sitesinin `hafızasıdır`.

WordPress kendi başına hiçbir veriyi(yazıları, şifreleri, yorumları) saklayamaz. Biri sitene girip yeni bir hesap açtığında veya sen yeni bir blog yazısı yayımladığımda, WordPress bu bilgileri alıp bir yere kaydetmek zorundadır. İşte o yer `MariaDB`'dir.

Projedeki spesifik görevleri şunlardır:
- `Dinamik Veri Depolama:` Sitenin adı, kurduğum temanın ayarları, yayınladığın postlar, yönetici(admin) şifren gibi tüm dinamik veriler MariaDB'nin içindeki tablolarda(satır ve sütunlar halinde) tutulur.
- `Kullanıcı Doğrulama:` Biri sitene giriş yapmak istediğinde, WordPress kullanıcının girdiği şifreyi alır, MariaDB'ye *"Bu şifre doğru mu?"* diye sorar. MariaDB kendi tablolarını kontrol eder ve WordPress'e onay veya ret gönderir.
- `İzole Veri Yönetimi:` Proje mimarisine göre veritabanının dış dünyaya(internet ortamına) tamamen kapalı olması gerekir. MariaDB sadece WordPress'in(aynı iç ağdaki `inception_network` üzerinden) erişebileceği güvenli bir kasadır.

```bash
YAML

mariadb:
    build: ./requirements/mariadb
    image: mariadb
    container_name: mariadb
    restart: always
    env_file: .env
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - inception_network
```

- `build & image:` Hazır bir Docker imajı kullanmak yasak olduğu için, Docker'a `./requirements/mariadb` dizinindeki kendi yazdığımız `Dockerfile`'ı okumasını ve sistemi sıfırdan "mariadb" adıyla inşa etmesini söyler.

- `container_name:` Çalışan konteynerin arka planda rastgele bir isim almasını engeller, doğrudan `mariadb` olarak etiketler.

- `restart: always:` Olası bir hata veya sunucu kapanıp açılması durumunda konteynerin otomatik olarak yeniden başlatılmasını garanti eder.

- `env_file: .env:` Veritabanı şifreleri (örneğin root şifresi) gibi hassas bilgileri compose dosyasına yazmak yerine, güvenli bir şekilde `.env` dosyasından okur.

- `volumes:` Veritabanı dosyalarının tutulduğu `/var/lib/mysql` dizinini, `db_data` adını verdiğimiz kalıcı disk alanına yönlendirir. Bu sayede konteyner silinse bile veriler kaybolmaz.

- `networks:` Bu servisi, diğer konteynerlerle güvenli iletişim kurabilmesi için `inception_network` adlı özel iç ağımıza dahil eder.

#### WordPress Servisi (Uygulama)

`WordPress`, İçerik Yönetim Sistemidir(CMS - Content Management System). İnternetteki web sitelerinin yaklaşık %40'ından fazlası WordPress altyapısı ile çalışır.

Basitçe ifade etmek gerekirse: Sıfırdan HTML, CSS ve PHP kodları yazarak bir web sitesi (örneğin bir blog, haber sitesi veya e-ticaret mağazası) yapmak yerine, WordPress sana hazır bir yönetim paneli ve altyapı sunar. Sen sadece "Yeni Yazı Ekle" butonuna basarsın, arka plandaki karmaşık kodları o halleder.

Projedeki spesifik görevleri şunlardır:
- `Dinamik İçerik Üretimi(PHP İşleme):` NGINX çok hızlı bir sunucudur ama sadece statik(sabit) dosyaları(HTML, resimler) anlamayı bilir. Biri sitene girdiğinde, NGINX bakar ki istenen dosya `.php` uzantılı. NGINX PHP kodunu okuyamaz. Bu yüzden isteği hemen arkadaki WordPress(PHP-FPM) konteynerine paslar. WordPress bu PHP kodlarını çalıştırır, gereken verileri MariaDB'den çeker, her şeyi yoğurup bir HTML sayfasına dönüştürür ve *"Al bunu müşteriye ver"* diyerek NGINX'e geri gönderir.
- `İçerik ve Site Yönetimi:` Proje bizden çalışan bir web sitesi yapmamızı istiyor. WordPress konteyneri ayağa kalktığında, sana görsel bir arayüz(admin paneli) sunar. Bu panel üzerinden; siteye yeni bir yönetici veya yazar(ikinci bir kullanıcı) ekleyebilirsin, sitenin temasını değiştirebilirsin, test amaçlı yazılar yayımlayabilirsin.

```bash
YAML

wordpress:
    ... (diğer ayarlar mariadb ile aynıdır)
    volumes:
      - wordpress_data:/var/www/wordpress
    depends_on:
      - mariadb
```

- `volumes:` WordPress çekirdek dosyalarının bulunduğu `/var/www/wordpress` dizinini kalıcı olan `wordpress_data` alanına bağlar.

- `depends_on: -mariadb` Bu komut mantıksal bir sıra oluşturur. WordPress'in çalışabilmesi için veritabanına bağlanması şarttır. Docker'a şunu söyler: *"MariaDB servisi tamamen çalışır hale gelmeden WordPress konteynerini başlatma."*

#### NGINX Servisi (Web Sunucusu)

`NGINX` inanılmaz derecede hızlı ve hafif bir web sunucusu(web server) ve ters vekil(reverse proxy) yazılımıdır.

Bu projedeki mimaride NGINX, dış dünyaya(internete veya bilgisayarına) açık olan tek kapıdır. MariaDB ve WordPress konteynerleri dışarıdan gelen bağlantılara tamamen kapalıdır. Kullanıcıların tüm istekleri önce NGINX'e gelir.

Projedeki spesifik görevleri şunlardır:
- `Web Sunucusu(Web Server):` Ziyaretçi sitene girdiğinde, NGINX bu isteği karşılar. Eğer istenen şey statik(sabit) bir dosya ise(örneğin bir resim dosyası, CSS stili, Javascript kodu), NGINX hiç kimseye sormadan bu dosyayı kendi üzerinden doğrudan ziyaretçiye gönderir. Çünkü statik dosyaları iletmekte dünyanın en hızlı yazılımlardan biridir.
- `Ters Vekil(Reverse Proxy):` Eğer ziyaretçinin isteği, çalıştırılması gereken dinamik bir PHP koduysa(örneğin ana sayfayı görüntülemek veya giriş yapmak), NGINX: *"Ben PHP dilinden anlamam"* der ve bu isteği ters vekil (reverse proxy) görevi görerek arkadaki WordPress(PHP-FPM) konteynerine iletir. WordPress HTML sayfasını hazırlayıp NGINX'e verir, NGINX de bunu ziyaretçiye sunar. Ziyaretçi hiçbir zaman arka planda bir WordPress veya MariaDB olduğunu görmez, sadece NGINX ile muhatap olur.
- `Güvenlik ve Şifreleme(SSL/TLS-Sadece Port 443)`: Bu projede özellikle bağlantının sadece TLSv1.2 veya TLSv1.3(HTTPS) üzerinden olmasını istiyor. 80 numaralı port(HTTP) yasaklıyor. Bu güvenlik duvarını kuran kişi NGINX. NGINX konteynerinin içine kendinden imzalı(self-signed) bir SSL sertifikası üretilir. NGINX ayar dosyasında(`nginx.conf`), dışarıdan gelen her isteğin bu sertifika ile şifrelenmesi gerektiği belirtilir. Böylece istemci ile sunucu arasındaki tüm trafik şifrelenmiş(HTTPS) olur.

```bash
YAML

nginx:
    ...
    ports:
      - "443:443"
    volumes:
      - wordpress_data:/var/www/wordpress
    depends_on:
      - wordpress
```

- `ports:` Sadece NGINX dış dünyaya açıktır. Ana makinemize (kendi bilgisayarımıza) 443 portundan (HTTPS) gelen tüm istekleri, NGINX konteynerinin 443 portuna yönlendirir. 80 portu (HTTPS) proje kuralları gereği kapalıdır.

- `volumes:` Dikkat edilirse WordPress ile aynı volume (`wordpress_data`) buraya da bağlanmıştır. NGINX, web sitesini (statil dosyaları) sunabilmek için WordPress'in dosyalarının bulunduğu `/var/www/wordpress` dizinine erişmek zorundadır.

- `depends_on: - wordpress:` NGINX'in sunacağı sayfaları WordPress (PHP-FPM) işlediği için, WordPress ayağa kalkmadan NGINX başlatılmaz.

#### Kalıcı Veri Tanımları (Volumes - Bind Mount)

```bash
YAML

volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/iekmen/data/wordpress
  db_data:
    ...
      device: /home/iekmen/data/mariadb
```
Konteynerler geçicidir (ephemeral). Bir konteyner yok edildiğinde içindeki her şey silinir. Bunu önlemek için "Bind Mount" yöntemi kullanılmıştır.

- Bu yapı, `wordpress_data` ve `db_data` isimli hacimleri doğrudan ana makinenin fiziksel diskindeki belirli klasörlere bağlar.

- `device: /home/iekmen/data/...` satırları ile verilerin konteyner içinde değil, doğrudan host makinede (`iekmen` kullanıcısının dizininde) fiziksel olarak tutulması zorunlu kılınmıştır.

#### Özel İç Ağ (Networks)

```bash
YAML

networks:
  inception_network:
    driver: bridge
    name: inception_network
```

- Tüm servislerin dahil olduğu Bridge türünde izole bir ağdır.

- Bu ağ sayesinde konteynerler (örneğin NGINX ve WordPress) IP adresi kullanmak zorunda kalmaz. NGINX, WordPress'e bağlanmak için sadece `wordpress` (servis adı) yazarak iletişim kurabilir, Docker arka planda bu isimleri otomatik olarak doğru IP adreslerine dönüştürür.

>### Sistemin İçindeki Veri Akışı Örneği

Sistemin nasıl çalıştığını somutlaştırmak için bir ziyaretçinin siteni açtığı o ilk saniyeyi düşün:
- Ziyaretçi tarayıcısına `https://localhost` yazar.
- İstek önce NGINX'e gelir. NGINX der ki: *"Benden ana sayfayı istiyorlar ama ben sadece HTML sunarım. Dinamik sayfayı oluşturması için bunu WordPress'e iletmeliyim."*
- WordPress isteği alır ve PHP kodlarını çalıştırır. Ana sayfadaki en son yazıları göstermek için MariaDB'te bir SQL sorgusu(soru) gönderir: *"Bana veritabanındaki son 5 yazıyı ver."*
- MariaDB içindeki tabloları tarar, 5 yazıyı bulur ve WordPress'e geri gönderir.
- WordPress bu veriyi HTML ile süsler, NGINX'e verir. NGINX de ziyaretçinin ekranına yansıtır.

Tüm bu süreç, `docker-compose.yml` dosyasında kurulan o sanal ağ(`inception_network`) üzerinden gerçekleşir.
