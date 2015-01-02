#monkeyServer.sh

![Monkey Web Server](https://i.imgur.com/jiQdi6e.png)

monkeyServer.sh is a simple shell script made to install a full web stack at low end boxes in about 5 minutes. It is built on top of [Monkey Web Server](http://monkey-project.com/), a really simple but feature rich web server. Monkey is really fast and stable, increadibly small and light on resources.

## WHAT IS INCLUDED ##
monkeyServer.sh comes in two flavors:

### DEFAULT FLAVOR ###
1. Monkey Web Server
2. PHP5-FPM
3. MariaDB
4. ConfigServer Firewall (CSF+LFD)
5. Adminer

**Running Process and Resource Usage for the Default Flavor:**

![Running Services](http://i.imgur.com/72ABGNM.png)
![Memory Usage](http://i.imgur.com/fl2gBno.png)
![SolusVM resources](http://i.imgur.com/lwnb8CX.png)

### NOSQL FLAVOR ###
This version don't include MariaDB or Adminer. Note that if you are using SQLite or any other database method that use files stored at your web root (like JSON files) you should configure the mandril plugin to deny access to the database files. This isn't built by monkeyServer.sh by default because we can't preview the filename patterns used by the users. Please refer to the [documentation](http://monkey-project.com/documentation/1.5/).

**Running Process and Resource Usage for the NoSQL flavor:**

![Running Process](http://i.imgur.com/5bLFTrS.png)
![Memory Usage](http://i.imgur.com/oR0xjSJ.png)
![SolusVM resources](http://i.imgur.com/afAYwfz.png)

## WHAT MODULES IS INCLUDED IN THE INSTALLATION ##
monkeyServer.sh will build your stack with a very small set of PHP5 and Monkey Web Server modules. This should be enough to 99% of the use cases. Bellow you will find a full list of the modules.

### MONKEY WEB SERVER MODULES ###
1. auth
2. liana
3. liana_ssl
4. logger
5. fastcgi
6. dirlisting
7. auth
8. polarssl
9. palm
10. mandril
11. cheetah
12. reverse_proxy

### PHP MODULES ###
1. mcrypt
2. mysqlnd
3. sqlite
4. pear
5. gd
6. xml-serializer

## MINIMUM REQUIREMENTS ##
1. RAM: 128MB (or just 64MB if you use the noSQL option)
2. HDD: 2GB
3. CPU: X86, X86_64 or ARM.
4. Distro: by now, only Debian Stable is supported

P.S.: You can, actually, cut the RAM requirement in a half. BUT, for the default flavor, this can be equal to really boring problems with MariaDB if you use InnoDB. So, we will say that minimum memory requirement to have a realiable server operation. Using less than that should work (with PHP-FPM tweaking you can run the noSQL with 16-24MB and the default with 32-64MB if you tweak MariaDB too) but is not recommended. In the near future, the embedded version should require only 8MB and the tweaks for PHP-FPM and MariaDB should be integrated.

## HOW TO INSTALL ##
Just run `/usr/bin/env bash <((wget -qO - https://raw.githubusercontent.com/alexandreteles/monkeyServer/master/monkeyServer.sh))` as root and follow the script instructions.

## HOW TO OBTAIN SUPPORT ##
At Low End Talk [official thread](http://lowendtalk.com/discussion/39893/debian-monkeyserver-sh-a-script-to-install-a-full-web-stack-at-lebs-in-5-minutes) or at the [issue page](https://github.com/alexandreteles/monkeyServer/issues) of the project at GitHub.

## WHAT IS PLANNED ##
1. A menu based installation (this will join the default and the noSQL versions);
2. A enableIPv6.sh script;
3. App installation capabilities;
4. FTP server installation;
5. Embedded version (to require only 32MB of RAM)

## LEARN MORE ##
1. Take a look at this (a bit outdated) [presentation](http://www.slideshare.net/startechconf/eduardo-silva-monkey-httpserver-everywhere) about Monkey Web Server
2. Read the official Monkey Web Server [documentation](http://monkey-project.com/documentation/1.5/). It's really handy.
3. Learn about the reverse_proxy module in Monkey Web Server reading [this](http://savita92.wordpress.com/2014/04/06/reverse-proxy-and-its-support-by-monkey-server/) article.
4. Learn how to setup the reverse_proxy reading [this](http://nikolanikov.wordpress.com/2013/08/14/monkey-proxy-reverse-plugin-preview/) tutorial.

## RESOURCES ##
GitHub: [https://github.com/alexandreteles/monkeyServer](https://github.com/alexandreteles/monkeyServer)
