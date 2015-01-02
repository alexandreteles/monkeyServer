#!/bin/bash
function clean_system {
	echo "Updating system..."
	apt-get update -y > /dev/null && apt-get upgrade -y > /dev/null && apt-get dist-upgrade -y > /dev/null && apt-get install -y sysv-rc-conf > /dev/null

	echo "Removing uneeded packages..."
	apt-get remove -y apache2 apache2-doc apache2-mpm-prefork apache2-utils apache2.2-bin apache2.2-common bind9 bind9-host bind9utils libbind9-80 rpcbind samba sendmail rmail sendmail-base sendmail-bin sendmail-cf sendmail-doc > /dev/null

	echo "Disabling uneeded services..."
	sysv-rc-conf xinetd off
	sysv-rc-conf saslauthd off
}

function install_csf {
	echo "Installing Exim4 MTA and re-enabling cron..."
	apt-get install -y mailutils cron  > /dev/null

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
	update-rc.d csf defaults
	update-rc.d csf enable
	update-rc.d lfd defaults
	update-rc.d lfd enable

	echo "Starting firewall..."
	service csf restart
	service lfd start
}

function install_monkey {
	echo "Installing PolarSSL build dependencies..."
	apt-get -y install build-essential cmake openssl libssl-dev  > /dev/null

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
	
	echo "Creating default vhost directory..."
	mkdir -p /srv/www/default

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

	echo "Installing monkey web server init file..."
	wget -P /etc/init.d/ https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/includes/init.d/monkey
	chmod 755 /etc/init.d/monkey
	update-rc.d monkey defaults
	update-rc.d monkey enable

	echo "Installing monkey config files..."
	mv /usr/local/etc/monkey/monkey.conf monkey.conf.default
	wget -P /usr/local/etc/monkey/ https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/includes/conf/monkey.conf
	echo "    #CUSTOM monkeyServer.sh plugins loading" >> /usr/local/etc/monkey/plugins.load
	echo "    Load /usr/local/plugins/monkey-dirlisting.so" >> /usr/local/etc/monkey/plugins.load
	echo "    Load /usr/local/plugins/monkey-logger.so" >> /usr/local/etc/monkey/plugins.load
	echo "    Load /usr/local/plugins/monkey-liana.so" >> /usr/local/etc/monkey/plugins.load
	echo "    Load /usr/local/plugins/monkey-logger.so" >> /usr/local/etc/monkey/plugins.load
	echo "    Load /usr/local/plugins/monkey-auth.so" >> /usr/local/etc/monkey/plugins.load
	mv /usr/local/etc/monkey/sites/default /usr/local/etc/monkey/sites/default.default
	wget -P /usr/local/etc/monkey/sites/ https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/includes/sites/default
}

function install_phpfpm {
	echo "Configuring dotDeb repositories..."
	touch /etc/apt/sources.list.d/dotdeb.list
	echo "deb http://packages.dotdeb.org stable all" >> /etc/apt/sources.list.d/dotdeb.list
	echo "deb-src http://packages.dotdeb.org stable all" >> /etc/apt/sources.list.d/dotdeb.list

	echo "Installing dotDeb GPG keys..."
	wget -q -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add -

	echo "Installing PHP-FPM and basic modules..."
	apt-get update -y  > /dev/null && apt-get upgrade -y  > /dev/null && apt-get dist-upgrade -y  > /dev/null && apt-get install -y php5-fpm php5-mcrypt php5-mysqlnd php5-sqlite php-pear php5-gd php-xml-serializer  > /dev/null

	echo "Configuring monkey fastcgi plugin and PHP-FPM pool..."
	mv /usr/local/etc/monkey/plugins/fastcgi/fastcgi.conf /usr/local/etc/monkey/plugins/fastcgi/fastcgi.conf.default
	wget -P /usr/local/etc/monkey/plugins/fastcgi/ https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/includes/plugins/fastcgi/fastcgi.conf
	mv /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.default
	wget -P /etc/php5/fpm/pool.d/ https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/includes/php5/www.conf
	echo "    Load /usr/local/plugins/monkey-fastcgi.so" >> /usr/local/etc/monkey/plugins.load

	restart_monkey
}

function restart_monkey {
	echo "Restarting IPv4 monkey instance..."
	service monkey restart
	if [ -f /etc/init.d/monkeyIPv6 ]
	then
		echo "Restarting IPv6 monkey instance..."
    	service monkeyIPv6 restart
	fi
	echo "Done."
	clear
}

function install_mariadb {
	echo "Configuring MariaDB repositories..."
	apt-get install -y python-software-properties
	apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
	add-apt-repository 'deb http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.0/debian wheezy main'

	echo "Installing MariaDB..."
	echo "Please, pay attention at this step as you will be required to insert your MariaDB root password..."
	read -p "Press [Enter] key to continue..." keep
	apt-get update -y > /dev/null && apt-get install -y mariadb-server  > /dev/null
}

function install_adminer {
	echo "Installing SQL Admin..."
	echo "-----------------------"
	echo "Avaiable vhosts: "
	find /srv/www/ -type d -exec basename {} \;
	echo "-----------------------"
	read -p "Install adminer to this vhost: " vHost
	mkdir -p /srv/www/${vHost}/sqladmin/
	wget -P /srv/www/${vHost}/sqladmin/ http://downloads.sourceforge.net/adminer/adminer-4.1.0.php
	mv /srv/www/${vHost}/sqladmin/adminer-4.1.0.php /srv/www/${vHost}/sqladmin/index.php
	wget -P /srv/www/${vHost}/sqladmin/ https://raw.github.com/vrana/adminer/master/designs/pokorny/adminer.css


	echo "[AUTH]" >> /usr/local/etc/monkey/sites/${vHost}
        echo "    Location /sqladmin"
        echo '    Title    "Please, type your credentials to continue."' >> /usr/local/etc/monkey/sites/${vHost}
        echo "    Users    /usr/local/etc/monkey/plugins/auth/vhosts/${vHost}/users.mk" >> /usr/local/etc/monkey/sites/${vHost}
        echo "" >> /usr/local/etc/monkey/sites/${vHost}

	read -p "Please, type the username that you will use to access the SQL Admin interface: " admineruser
	read -p "Please, type the password that you will use to access the SQL Admin interface: " adminerpass

	echo "Configuring SQL Admin authentication..."
	mkdir -p /usr/local/etc/monkey/plugins/auth/vhosts/${vHost}/
	mk_passwd -c /usr/local/etc/monkey/plugins/auth/vhosts/${vHost}/users.mk ${admineruser} ${adminerpass}
}

function vhost_is_redirect {
	read -p "Virtual host hostname: " vhostname
	read -p "URL to redirect: " redirecturl
	touch /usr/local/etc/monkey/sites/${vhostname}
	echo "[HOST]" >> /usr/local/etc/monkey/sites/${vhostname}
	echo "    ServerName ${vhostname}" >> /usr/local/etc/monkey/sites/${vhostname}
	echo "    Redirect ${redirecturl}" >> /usr/local/etc/monkey/sites/${vhostname}
	echo "[LOGGER]" >> /usr/local/etc/monkey/sites/${vhostname}
	echo "    AccessLog /var/log/monkey/${1}.access.log" >> /usr/local/etc/monkey/sites/${vhostname}
	echo "    ErrorLog /var/log/monkey/${1}.error.log" >> /usr/local/etc/monkey/sites/${vhostname}
        echo "" >> /usr/local/etc/monkey/sites/${vhostname}
}

function vhost_is_site {
	read -p "Virtual host hostname: " vhostname
	mkdir -p /srv/www/${vhostname}
	touch /usr/local/etc/monkey/sites/${vhostname}
	echo "[HOST]" >> /usr/local/etc/monkey/sites/${vhostname}
	echo "    ServerName ${vhostname}" >> /usr/local/etc/monkey/sites/${vhostname}
	echo "    DocumentRoot /srv/www/${vhostname}" >> /usr/local/etc/monkey/sites/${vhostname}
	echo "[LOGGER]" >> /usr/local/etc/monkey/sites/${vhostname}
	echo "    AccessLog /var/log/monkey/${1}.access.log" >> /usr/local/etc/monkey/sites/${vhostname}
	echo "    ErrorLog /var/log/monkey/${1}.error.log" >> /usr/local/etc/monkey/sites/${vhostname}
	echo "[ERROR_PAGES]" >> /usr/local/etc/monkey/sites/${vhostname}
        echo "    404  404.html" >> /usr/local/etc/monkey/sites/${vhostname}
        echo "" >> /usr/local/etc/monkey/sites/${vhostname}
}

function create_vhost {
	echo "Creating new vhost..."
	echo "---------------------"
	read -p "Do you want to redirect this vhost to a URL? (yes or no): " isredirect
	if [[ "$isredirect" = "yes" ]]; then
		vhost_is_redirect
	else
		vhost_is_site
	fi
	restart_monkey
}

function remove_vhost {
	echo "Removing a existing vhost..."
	echo "-----------------------"
	echo "Avaiable vhosts: "
	find /usr/local/etc/monkey/sites/ -type d -exec basename {} \;
	echo "-----------------------"
	read -p "Remove this vhost: " rmvhost
	rm -f /usr/local/etc/monkey/sites/${rmvhost}
	rm -rf /srv/www/${rmvhost}
	restart_monkey
}

function enable_ipv6 {
	echo "Installing IPv6 support..."
	wget -P /usr/local/etc/monkey/ https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/includes/conf/monkeyIPv6.conf
	echo "Installing monkeyIPv6 web server init file..."
	wget -P /etc/init.d/ https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/includes/init.d/monkeyIPv6
	chmod 755 /etc/init.d/monkeyIPv6
	update-rc.d monkeyIPv6 defaults
	update-rc.d monkeyIPv6 enable
}

function quit {
	exit
}

echo "This script is licensed under the GPLv3 License."
echo -e "Take a look at LICENSE file on our GIT repo to learn more.\n"
echo -e "Written by Alexandre Teles - EJECT-UFBA\n\n"

while :
do
        echo -e "\n\n"
        echo "MonkeyServer.sh"
        echo "---------------"
        echo -e "\n\n"
	echo "1. Clean system (run this before installing the web server)"
	echo "2. Install Monkey Web Server"
	echo "3. Install PHP-FPM support"
	echo "4. Install MariaDB DBMS"
	echo "5. Install Adminer SQL Admin"
	echo "6. Install ConfigServer Firewall"
	echo "7. Install Monkey WS IPv6 support"
	echo "8. Create a new vhost"
	echo "9. Remove a existing vhost"
	echo "10. Exit monkeyServer.sh"
	echo -e "---------------\n\n"

	read -p "My option is: " option

	case "$option" in
		"1")
    		clean_system
    		;;
		"2")
    		install_monkey
    		;;
		"3")
			install_phpfpm
			;;
		"4")
			install_mariadb
			;;
		"5")
			install_adminer
			;;
		"6")
			install_csf
			;;
		"7")
			enable_ipv6
			;;
		"8")
			create_vhost
			;;
		"9")
			remove_vhost
			;;
		"10")
			quit
			;;
		*)
    		true
    	;;
	esac
done

echo "All done. Please restart your machine now or restart monkey web server using: service monkey restart or service monkeyIPv6 restart."
echo "Thank you!"
