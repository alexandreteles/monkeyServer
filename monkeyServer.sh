#!/bin/sh

echo "This script will install LMPM stack (Linux, Monkey Web Server, PHP-FPM, MariaDB) on your machine."
read -p "Press [Enter] key to continue the installation process..."

echo "Removing uneeded packages..."
apt-get remove apache2 bind9 samba sendmail

echo "Disabling uneeded services..."
update-rc.d xinetd disable
update-rc.d saslauthd disable

echo "Installing PolarSSL build dependencies..."
apt-get update && apt-get upgrade && apt-get dist-upgrade && apt-get -y install build-essential cmake openssl libssl-dev

echo "Entering temp. dir..."
cd /tmp/

echo "Downloading PolarSSL sources..."
wget https://polarssl.org/download/latest-stable

echo "Extracting PolarSSL sources and entering source dir..."
tar xvzf polarssl-1.*
cd polarssl-1.*

echo "Configuring build environment..."
cmake -DUSE_SHARED_POLARSSL_LIBRARY=on .

echo "Compiling PolarSSL sources..."
make

echo "Installing PolarSSL libraries..."
make install

echo "Exiting build directory..."
cd ../

echo "Removing apache2 Web Server..."
apt-get -y remove apache2

echo "Creating web directory..."
mkdir -p /srv/www

echo "Creating web server user and group..."
useradd -s /usr/sbin/nologin -M -d /srv/www monkey

echo "Downloading monkey web server sources..."
wget http://monkey-project.com/releases/1.5/monkey-1.5.5.tar.gz

echo "Extracting sources and entering source dir..."
tar zxvf monkey-1*
cd monkey-1*

echo "Configuring build dependencies and flags..."
CFLAGS="-I/usr/local/include/polarssl/" \
LDFLAGS="-L/tmp/polarssl-1.3.9/library/ -Wl,-rpath=/tmp/polarssl-1.3.9/library/" \
./configure --prefix=/usr/local \
--datadir=/srv/www \
--logdir=/var/log/monkey \
--sysconfdir=/usr/local/etc/monkey \
--safe-free \
--default-user=monkey \
--default-port=80 \
--enable-plugins=auth,liana,liana_ssl,logger,fastcgi,dirlisting,auth,polarssl,palm,mandril,cheetah,reverse_proxy


echo "Compiling and installing monkey web server..."
make
make install

echo "Setting the user monkey as owner of /var/log/monkey..."
chown -R monkey:monkey /var/log/monkey

echo "Installing supervisor to control monkey web server startup and failures..."
apt-get install -y supervisor
