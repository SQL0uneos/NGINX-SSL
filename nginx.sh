#!/bin/bash

if [ `id -u` != 0 ]
then
        clear
        echo "le mode root est nécessaire..."
        exit
else
        #Récupération des dépendances
        apt-get update
	apt-get install -y git tree software-properties-common dirmngr apt-transport-https ufw
	apt-get install -y curl build-essential make gcc libpcre3 libpcre3-dev libpcre++-dev zlib1g-dev libbz2-dev libxslt1-dev libxml2-dev libgd2-xpm-dev libgeoip-dev libgoogle-perftools-dev libperl-dev libssl-dev libcurl4-openssl-dev libatomic-ops-dev 

        #Installation de PCRE DEP
	cd /opt
	wget ftp://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz
	tar -zxf pcre-8.43.tar.gz
	cd pcre-8.43
	./configure
	make
	make install
	echo 'Fait'

	#Installation de OPENSSL DEP
	cd /opt
	wget http://www.openssl.org/source/openssl-1.1.1c.tar.gz
	tar -zxf openssl-1.1.1c.tar.gz
	cd openssl-1.1.1c
	./configure darwin64-x86_64-cc --prefix=/usr
	make
	make install
	echo 'fait'

	#Installation de ZLIB DEP
	cd /opt/
	wget http://zlib.net/zlib-1.2.11.tar.gz
	tar -zxf zlib-1.2.11.tar.gz
	cd zlib-1.2.11
	./configure
	make
	make install
	echo 'Fait'
	
	#Installation de NGINX

	cd /opt/
	wget https://nginx.org/download/nginx-1.17.4.tar.gz
	tar zxf nginx-1.17.4.tar.gz
	cd nginx-1.17.4

	cd /opt/nginx-1.17.4
	./configure --sbin-path=/usr/local/nginx/nginx --conf-path=/usr/local/nginx/nginx.conf --pid-path=/usr/local/nginx/nginx.pid --with-openssl=/opt/openssl-1.1.1c --with-pcre=/opt/pcre-8.43 --with-zlib=/opt/zlib-1.2.11 --with-http_ssl_module --with-stream --with-stream_ssl_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module
	
	make && make install


        # Modification de la fichier conf pour changer le port par défaut
        cd /usr/local/nginx/conf
        sed -i -e "s/#pid / pid /g" nginx.conf
        cd /etc/init.d
        wget https://gist.github.com/sairam/5892520/raw/b8195a71e944d46271c8a49f2717f70bcd04bf1a/etc-init.d-nginx
        chmod +x etc-init.d-nginx


###########service.nginx########################
cd /lib/systemd/system

echo "
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target" >> nginx.service

#######################

        systemctl enable nginx
        echo "Regarde si le server web est bien là : http://YOUR-IP-SERVER:80"
fi



cd /etc/ssll

#creation d'un dossier ssl pour le certificat
#mkdir ssll

#cd ssll

# genere un certificat de 2048 bits
 NAME="RSA"
 TIME="365"

# genere une cle prive
echo -e "\nGenerer la clé serveur\n"
if ( ! openssl genrsa -out "$NAME.key" 2048 >> /dev/null 2>&1 ) ; then echo -e "Error" ; exit 1 ; fi


# cree un csr avec la cle privee
echo -e "\n\nGenerer requête certificat \n"
openssl req -new -key "$NAME.key" -out "$NAME.csr"

# cree le certificat
echo -e "\n\nGenerer certificat\n"
openssl x509 -req -days "$TIME" -in "$NAME.csr" -signkey "$NAME.key" -out "$NAME.crt"

rm "$NAME.csr"
echo -e "\n$NAME.key: votre cle privee\n$NAME.crt: votre certificat serveur"

exit 0
