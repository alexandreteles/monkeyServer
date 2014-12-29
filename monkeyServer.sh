#!/bin/sh
echo "This script is licensed under the GPLv3 License."
echo "Take a look at LICENSE file on our GIT repo to learn more.\n"
echo "Written by Alexandre Teles - EJECT-UFBA\n\n"

echo "This script will install LMPM stack (Linux, Monkey Web Server, PHP-FPM, MariaDB) on your machine."
echo "MonkeyServer.sh will install a firewall (CSF) a IDS (LFD) and a light MTA to handle mail information as well."
read -p "Press [Enter] key to continue the installation process or CTRL+C to exit..." keep

echo "Updating system..."
apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y && apt-get install -y sysv-rc-conf

echo "Removing uneeded packages..."
apt-get remove -y apache2 apache2-doc apache2-mpm-prefork apache2-utils apache2.2-bin apache2.2-common bind9 bind9-host bind9utils libbind9-80 rpcbind samba sendmail rmail sendmail-base sendmail-bin sendmail-cf sendmail-doc

echo "Disabling uneeded services..."
sysv-rc-conf xinetd off
sysv-rc-conf saslauthd off

echo "Installing Exim4 MTA and re-enabling cron..."
apt-get install -y exim4-daemon-light cron

echo "Installing PolarSSL build dependencies..."
apt-get -y install build-essential cmake openssl libssl-dev

echo "Entering temp. dir..."
cd /tmp/

echo "Downloading PolarSSL sources..."
wget https://polarssl.org/download/latest-stable

echo "Extracting PolarSSL sources and entering source dir..."
tar xzf latest-stable
cd polarssl-1.*

echo "Configuring build environment..."
cmake -DUSE_SHARED_POLARSSL_LIBRARY=on .

echo "Compiling PolarSSL sources..."
make

echo "Installing PolarSSL libraries..."
make install

echo "Exiting build directory..."
cd -

echo "Creating web root directory..."
mkdir -p /srv/www

echo "Creating web server user and group..."
useradd -s /usr/sbin/nologin -M -d /srv/www monkey

echo "Downloading monkey web server sources..."
wget http://monkey-project.com/releases/1.5/monkey-1.5.5.tar.gz

echo "Extracting sources and entering source dir..."
tar zxf monkey-1*
cd monkey-1*

echo "Configuring build dependencies and flags..."
CFLAGS="-I/usr/local/include/polarssl/" \
LDFLAGS="-L/usr/local/lib/ -Wl,-rpath=/usr/local/lib/"

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
cd -

echo "Setting the user monkey as owner of /var/log/monkey and /var/run/monkey..."
mkdir -p /var/log/monkey
chown -R monkey:monkey /var/log/monkey
mkdir -p /usr/local/run/monkey/supervisor
chown -R monkey:monkey /usr/local/run/monkey

echo "Installing supervisor to control monkey web server startup and failures..."
apt-get install -y supervisor

echo "Installing monkey Supervisor config file..."
wget -P /etc/supervisor/conf.d/ https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/includes/supervisor/monkey.conf

echo "Installing monkey config files..."
mv /usr/local/etc/monkey/monkey.conf monkey.conf.default
wget -P /usr/local/etc/monkey/ https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/includes/conf/monkey.conf
echo "#CUSTOM MonkeyServer.sh plugins loading" >> /usr/local/etc/monkey/plugins.load
echo "Load /usr/local/plugins/monkey-dirlisting.so" >> /usr/local/etc/monkey/plugins.load
echo "Load /usr/local/plugins/monkey-fastcgi.so" >> /usr/local/etc/monkey/plugins.load
echo "Load /usr/local/plugins/monkey-logger.so" >> /usr/local/etc/monkey/plugins.load
echo "Load /usr/local/plugins/monkey-liana.so" >> /usr/local/etc/monkey/plugins.load
echo "Load /usr/local/plugins/monkey-logger.so" >> /usr/local/etc/monkey/plugins.load
echo "Load /usr/local/plugins/monkey-auth.so" >> /usr/local/etc/monkey/plugins.load
mv /usr/local/etc/monkey/sites/default /usr/local/etc/monkey/sites/default.default
wget -P /usr/local/etc/monkey/sites/ https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/includes/sites/default

echo "Configuring dotDeb repositories..."
touch /etc/apt/sources.list.d/dotdeb.list
echo "deb http://packages.dotdeb.org stable all" >> /etc/apt/sources.list.d/dotdeb.list
echo "deb-src http://packages.dotdeb.org stable all" >> /etc/apt/sources.list.d/dotdeb.list

echo "Installing dotDeb GPG keys..."
wget -q -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add -

echo "Installing PHP-FPM and basic modules..."
apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y && apt-get install -y php5-fpm php5-mcrypt php5-mysqlnd php5-sqlite php-pear php5-gd php-xml-serializer

echo "Configuring monkey fastcgi plugin and PHP-FPM pool..."
mv /usr/local/etc/monkey/plugins/fastcgi/fastcgi.conf /usr/local/etc/monkey/plugins/fastcgi/fastcgi.conf.default
wget -P /usr/local/etc/monkey/plugins/fastcgi/ https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/includes/plugins/fastcgi/fastcgi.conf
mv /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.default
wget -P /etc/php5/fpm/pool.d/ https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/includes/php5/www.conf

echo "Configuring MariaDB repositories..."
apt-get install -y python-software-properties
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
add-apt-repository 'deb http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.0/debian wheezy main'

echo "Installing MariaDB..."
echo "Please, pay attention at this step as you will be required to insert your MariaDB root password."
apt-get update -y && apt-get install -y mariadb-server

echo "Installing SQL Admin..."
mkdir -p /srv/www/sqladmin/
wget -P /srv/www/sqladmin/ -O index.php http://downloads.sourceforge.net/adminer/adminer-4.1.0.php
wget -P /srv/www/sqladmin/ https://raw.github.com/vrana/adminer/master/designs/pokorny/adminer.css

read -p "Please, type the username that you will use to access the SQL Admin interface: " ADMINERUSER
read -p "Please, type the password that you will use to access the SQL Admin interface: " ADMINERPASS

echo "Configuring SQL Admin authentication..."
mk_passwd -c /usr/local/etc/monkey/plugins/auth/users.mk  ${ADMINERUSER} ${ADMINERPASS}

echo "Entering /tmp dir..."
cd /tmp

echo "Donwloading ConfigServer Firewall..."
wget http://www.configserver.com/free/csf.tgz

echo "Extractin sources and entering dir..."
tar -xzf csf.tgz
cd csf

echo "Installing CSF and dependencies..."
apt-get install -y libwww-perl
sh install.sh

echo "Verifying IPTables modules..."
perl /usr/local/csf/bin/csftest.pl

# CSF configuration adapted from Centminmod

echo "Configuring CSF firewall..."
EMAIL="root@localhost"
cp -a /etc/csf/csf.conf /etc/csf/csf.conf-bak
egrep '^UDP_|^TCP_|^DROP_NOLOG' /etc/csf/csf.conf
cat >>/etc/csf/csf.pignore<<EOF
user:mysql
exe:/usr/sbin/mysqld
cmd:/usr/sbin/mysqld
user:monkey
exe:/usr/local/bin/banana
exe:/usr/local/bin/monkey
EOF
sed -i "s/LF_ALERT_TO = ""/LF_ALERT_TO = "$EMAIL"/g" /etc/csf/csf.conf
sed -i 's/LF_DSHIELD = "0"/LF_DSHIELD = "86400"/g' /etc/csf/csf.conf
sed -i 's/LF_SPAMHAUS = "0"/LF_SPAMHAUS = "86400"/g' /etc/csf/csf.conf
sed -i 's/LF_EXPLOIT = "300"/LF_EXPLOIT = "86400"/g' /etc/csf/csf.conf
sed -i 's/LF_DIRWATCH = "300"/LF_DIRWATCH = "86400"/g' /etc/csf/csf.conf
sed -i 's/LF_INTEGRITY = "3600"/LF_INTEGRITY = "0"/g' /etc/csf/csf.conf
sed -i 's/LF_PARSE = "5"/LF_PARSE = "20"/g' /etc/csf/csf.conf
sed -i 's/LF_PARSE = "600"/LF_PARSE = "20"/g' /etc/csf/csf.conf
sed -i 's/PS_LIMIT = "10"/PS_LIMIT = "15"/g' /etc/csf/csf.conf
sed -i 's/PT_LIMIT = "60"/PT_LIMIT = "0"/g' /etc/csf/csf.conf
sed -i 's/PT_USERPROC = "10"/PT_USERPROC = "0"/g' /etc/csf/csf.conf
sed -i 's/PT_USERMEM = "200"/PT_USERMEM = "0"/g' /etc/csf/csf.conf
sed -i 's/PT_USERTIME = "1800"/PT_USERTIME = "0"/g' /etc/csf/csf.conf
sed -i 's/PT_LOAD = "30"/PT_LOAD = "600"/g' /etc/csf/csf.conf
sed -i 's/PT_LOAD_AVG = "5"/PT_LOAD_AVG = "15"/g' /etc/csf/csf.conf
sed -i 's/PT_LOAD_LEVEL = "6"/PT_LOAD_LEVEL = "8"/g' /etc/csf/csf.conf
sed -i 's/LF_DISTATTACK = "0"/LF_DISTATTACK = "1"/g' /etc/csf/csf.conf
sed -i 's/LF_DISTFTP = "0"/LF_DISTFTP = "1"/g' /etc/csf/csf.conf
sed -i 's/LF_DISTFTP_UNIQ = "3"/LF_DISTFTP_UNIQ = "6"/g' /etc/csf/csf.conf
sed -i 's/LF_DISTFTP_PERM = "3600"/LF_DISTFTP_PERM = "6000"/g' /etc/csf/csf.conf
sed -i 's/DENY_IP_LIMIT = \"100\"/DENY_IP_LIMIT = \"200\"/' /etc/csf/csf.conf
sed -i 's/DENY_TEMP_IP_LIMIT = \"100\"/DENY_TEMP_IP_LIMIT = \"200\"/' /etc/csf/csf.conf
sed -i 's/UDPFLOOD = \"0\"/UDPFLOOD = \"1\"/g' /etc/csf/csf.conf
sed -i 's/UDPFLOOD_ALLOWUSER = \"named\"/UDPFLOOD_ALLOWUSER = \"named nsd\"/g' /etc/csf/csf.conf

echo "Disabling CSF Testing mode (activates firewall)..."
sed -i 's/TESTING = "1"/TESTING = "0"/g' /etc/csf/csf.conf
csf -r

echo "Starting firewall..."
service csf restart
service lfd start

echo "All done. Please restart your machine now or start monkey web server using: banana start."
echo "Thank you!"
