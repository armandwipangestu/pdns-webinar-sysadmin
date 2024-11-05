#!/usr/bin/env bash

# Update & Upgrade Package
sudo apt update && sudo apt upgrade

# Install MariaDB Server & Client
sudo apt install mariadb-server mariadb-client

# Membuat Database untuk PowerDNS di MariaDB
sudo mysql -u root -p
# ```sql
# CREATE DATABASE `powerdns` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# GRANT ALL PRIVILEGES ON `powerdns`.* TO 'powerdnsuser'@'localhost' IDENTIFIED BY 'YOUR_PASSWORD_HERE';
# ```

# Menontaktifkan service systemd-resolved karena akan bentrok dengan PowerDNS nantinya
sudo systemctl disable --now systemd-resolved

# Menghapus file konfigurasi system service
sudo rm -rf /etc/resolv.conf

# Membuat file `/etc/resolv.conf` baru dengan nameserver atau DNS Google
sudo echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Install package PowerDNS Server dan PowerDNS Database Backend
sudo apt-get install pdns-server pdns-backend-mysql -y

# Membuat skema database dari bawaan PowerDNS
sudo mysql -u root -p powerdns </usr/share/doc/pdns-backend-mysql/schema.mysql.sql
# ```sql
# use powerdns;
# show tables;
# ```

# Backup file konfigurasi origin powerdns
sudo mv /etc/powerdns/pdns.conf /etc/powerdns/pdns.conf.orig

# Membuka file konfigurasi untuk mengedit
sudo vim /etc/powerdns/pdns.conf
# ```conf
# # MySQL Configuration
# launch=gmysql
# gmysql-host=127.0.0.1
# gmysql-port=3306
# gmysql-dbname=powerdns
# gmysql-user=powerdnsuser
# gmysql-password=secretpassword
# gmysql-dnssec=yes

# local-address=0.0.0.0
# local-port=5300

# # API
# api=yes
# api-key=c2dd627dd641d517e1f455ca85eccd9b2bd75b6fbfb807fd69ba14a8c90e197c

# # Webserver
# webserver=yes
# webserver-address=0.0.0.0
# webserver-port=8081
# webserver-allow-from=0.0.0.0/0
# webserver-password=secretpassword
# webserver-loglevel=none

# daemon=yes
# guardian=yes
# default-soa-content=ns1.your-domain.com arman.your-domain.com 0 3600 600 1209600 3600
# log-dns-details=yes
# log-dns-queries=yes
# loglevel=5
# setgid=pdns
# setuid=pdns
# distributor-threads=4
# receiver-threads=3
# signing-threads=4
# ```

# Menonaktifkan service `pdns`
sudo systemctl stop pdns

# Tes koneksi ke database
sudo pdns_server --daemon=no --guardian=no --loglevel=9

# Menjalankan service powerdns
sudo systemctl start pdns

# Mengecek koneksi `pdns` dengan package `ss` atau `Socket Statistics`
sudo ss -alnp4 | grep pdns

# Membuat DNS zone baru
pdnsutil create-zone your-domain.com

# Menambahkan record pada zone yang baru dibuat
pdnsutil edit-zone your-domain.com
# ```
# your-domain.com   3600    IN      SOA     ns1.your-domain.com arman.your-domain.com 1 10800 3600 604800 3600
# your-domain.com   86400   IN      NS      ns1.your-domain.com.
# your-domain.com   86400   IN      NS      ns2.your-domain.com.
# your-domain.com   3600    IN      A       34.101.90.211
# ns1.your-domain.com       172800  IN      A       34.101.90.211
# ns2.your-domain.com       172800  IN      A       34.101.90.211
# ```

# Install Nginx
sudo apt install nginx

# Create index.html
sudo bash -c "cat > /var/www/html/index.html << 'EOF'
<p>PowerDNS Authoritative Server</p>
<p>Domain: devnull.my.id</p>
<p id=\"serverIpv4\">Fetching server's IP address...</p>
<p>Created By: Arman Dwi Pangestu A.K.A devnull</p>

<script>
    fetch(window.location.href)
        .then((response) => {
            const serverIP = response.headers.get('X-Server-IP');
            if (serverIP) {
                document.getElementById('serverIpv4').textContent =
                    'Server's Public IPv4 Address: ' + serverIP;
            } else {
                document.getElementById('serverIpv4').textContent =
                    'Server IP header not found.';
            }
        })
        .catch((error) => {
            console.error('Error fetching server IP:', error);
            document.getElementById('serverIpv4').textContent =
                'Failed to fetch server IP.';
        });
</script>
EOF"
