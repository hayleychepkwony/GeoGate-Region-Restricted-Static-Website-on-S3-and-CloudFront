#!/bin/bash
# EC2 user data for Amazon Linux 2023: installs a complete WordPress stack (Apache + PHP + MariaDB).
# The database password is generated on the server and never stored in this repo.
set -euxo pipefail

dnf update -y
dnf install -y wget httpd php-fpm php-mysqli php-json php php-gd php-mbstring php-xml mariadb105-server

systemctl enable --now mariadb httpd php-fpm

# --- Database -------------------------------------------------------------
DB_PASS=$(openssl rand -hex 16)
mysql <<SQL
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
SQL

# --- WordPress files ------------------------------------------------------
cd /tmp
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* /var/www/html/
cd /var/www/html
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/wordpress/; s/username_here/wpuser/; s/password_here/$DB_PASS/" wp-config.php

# Replace the 8 placeholder security keys/salts with random values
for i in 1 2 3 4 5 6 7 8; do
  sed -i "0,/put your unique phrase here/s//$(openssl rand -hex 32)/" wp-config.php
done

# Allow pretty permalinks (.htaccess) and set permissions
sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
chown -R apache:apache /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

systemctl restart httpd php-fpm
