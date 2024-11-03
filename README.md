<h2 align="center">Membangun DNS Authoritative Server Menggunakan PowerDNS - Webinar SysAdmin</h2>

<img src="assets/banner.png" alt="Banner">

<p align="center">Repository ini adalah panduan untuk membangun DNS Authoritative Server menggunakan PowerDNS pada Webinar SysAdmin yang diadakan pada tanggal XX bulan November tahun 2024.</p>

## Daftar Isi

- [Instalasi PowerDNS di Ubuntu Server](#instalasi-powerdns-di-ubuntu-server)
  - [Langkah 1: Install dan Konfigurasi MariaDB Server](#langkah-1-install-dan-konfigurasi-mariadb-server)
  - [Langkah 2: Install PowerDNS](#langkah-2-install-powerdns)
  - [Langkah 3: Konfigurasi PowerDNS](#langkah-3-konfigurasi-powerdns)
  - [Langkah 4: Membuat DNS Zone dan Record](#langkah-4-membuat-dns-zone-dan-record)
  - [Langkah 5: Mengubah Childname NS & NS di Panel Hosting](#langkah-5-mengubah-childname-ns--ns-di-panel-hosting)

## Instalasi PowerDNS di Ubuntu Server

Ikuti langkah dibawah ini untuk proses instalasi dan konfigurasi `PowerDNS` dengan `MySQL` atau `MariaDB` sebagai `backend` database.

### Langkah 1: Install dan Konfigurasi MariaDB Server

- Update dan Upgrade sistem package:

```bash
sudo apt update && sudo apt upgrade
```

- Install MariaDB Server dan Client:

```bash
sudo apt install mariadb-server mariadb-client
```

- Membuat database untuk powerdns di MariaDB

```bash
sudo mysql -u root -p
```

```sql
CREATE DATABASE `powerdns` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

- Membuat akun atau user untuk powerdns kemudian berikan akses ke database `powerdns`

```sql
GRANT ALL PRIVILEGES ON `powerdns`.* TO 'powerdnsuser'@'localhost' IDENTIFIED BY 'YOUR_PASSWORD_HERE';
```

### Langkah 2: Install PowerDNS

- Menontaktifkan service systemd-resolved karena akan bentrok dengan PowerDNS nantinya

```bash
sudo systemctl disable --now systemd-resolved
```

- Menghapus file konfigurasi system service

```bash
sudo rm -rf /etc/resolv.conf
```

- Membuat file `/etc/resolv.conf` baru dengan nameserver atau DNS Google

```bash
sudo echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

- Install package PowerDNS Server dan PowerDNS Database Backend

```bash
sudo apt-get install pdns-server pdns-backend-mysql -y
```

- Membuat skema database dari bawaan PowerDNS

```bash
sudo mysql -u root -p powerdns < /usr/share/doc/pdns-backend-mysql/schema.mysql.sql
```

### Langkah 3: Konfigurasi PowerDNS

Melakukan konfigurasi file lokal PowerDNS agar konek ke dalam Database

- Backup file konfigurasi origin powerdns

```bash
sudo mv /etc/powerdns/pdns.conf /etc/powerdns/pdns.conf.orig
```

- Membuka file konfigurasi untuk mengedit

```bash
sudo vim /etc/powerdns/pdns.conf
```

```bash
# MySQL Configuration
launch=gmysql
gmysql-host=127.0.0.1
gmysql-port=3306
gmysql-dbname=powerdns
gmysql-user=powerdnsuser
gmysql-password=YOUR_PASSWORD_HERE
gmysql-dnssec=yes

# API
api=yes
api-key=YOUR_API_KEY_HERE

# Webserver
webserver=yes
webserver-address=<loopback/your_second_ip>
webserver-port=8081
webserver-allow-from=127.0.0.1,<your_second_ip>
webserver-password=<YOUR_WEB_SERVER_PASSWORD>
```

- Menonaktifkan service `pdns`

```bash
sudo systemctl stop pdns
```

- Tes koneksi ke database

> [!NOTE]
> Pastikan bahwa powerdns berhasil melakukan koneksi ke dalam database
>
> ```bash
> gmysql Connection successful. Connected to database 'powerdns' on '127.0.0.1'.
> ```

```bash
sudo pdns_server --daemon=no --guardian=no --loglevel=9
```

- Menjalankan service powerdns

```bash
sudo systemctl start pdns
```

- Mengecek koneksi `pdns` dengan package `ss` atau `Socket Statistics`

> [!IMPORTANT]
> Pastikan bahwa `powerdns` berhasil bejalan pada protocol `tcp` dan `udp` dengan state `UNCONN` dan `LISTEN` di port `53` dan `8081`

```bash
sudo ss -alnp4 | grep pdns
```

### Langkah 4: Membuat DNS Zone dan Record

### Langkah 5: Mengubah Childname NS & NS di Panel Hosting
