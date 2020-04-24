FROM ubuntu:20.04
MAINTAINER Edson Cunha <efcunha@edsoncunha.eti.br>

# Surpress Upstart errors/warning
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Envinroment variable to disable interactivity. 
# Variável de ambiente para desativar a interatividade. 
ENV DEBIAN_FRONTEND=noninteractive

# Files for drivers installation 
# Copia dos drivers para instalação 
COPY ./files/* /opt/
COPY ./scripts/* /home/scripts/ 

# Update base image
# Add sources for latest nginx
# Install software requirements
RUN apt-get update && \
apt-get install -y software-properties-common && \
apt-get update && \
apt-get upgrade -y && \
BUILD_PACKAGES="supervisor nginx php7.4 php7.4-bz2 php7.4-pdo php7.4-common php7.4-cgi php7.4-cli php7.4-dba php7.4-dev php7.4-bcmath php7.4-fpm php7.4-gmp php7.4-mysql php7.4-tidy php7.4-sqlite3 php7.4-json php7.4-opcache php7.4-sybase php7.4-curl php7.4-ldap php7.4-phpdbg php7.4-imap php7.4-xml php7.4-xsl php7.4-intl php7.4-zip php7.4-odbc php7.4-mbstring php7.4-readline php7.4-gd php7.4-interbase php7.4-snmp php7.4-xmlrpc php7.4-soap php7.4-pspell php7.4-pgsql php7.4-enchant libaio1 unzip pwgen" && \
apt-get -y install $BUILD_PACKAGES && \
apt-get remove --purge -y software-properties-common && \
apt-get autoremove -y && \
apt-get clean && \
apt-get autoclean && \
echo -n > /var/lib/apt/extended_states && \
rm -rf /var/lib/apt/lists/* && \
rm -rf /usr/share/man/?? && \
rm -rf /usr/share/man/??_*

# tweak nginx config
RUN sed -i -e"s/worker_processes  1/worker_processes 5/" /etc/nginx/nginx.conf && \
sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf && \
echo "daemon off;" >> /etc/nginx/nginx.conf

# tweak php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.4/fpm/php.ini && \
sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.4/fpm/php.ini && \
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.4/fpm/php.ini && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.4/fpm/php-fpm.conf && \
sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.4/fpm/pool.d/www.conf && \
sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.4/fpm/pool.d/www.conf && \
sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.4/fpm/pool.d/www.conf && \
sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.4/fpm/pool.d/www.conf && \
sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.4/fpm/pool.d/www.conf && \
sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.4/fpm/pool.d/www.conf

# fix ownership of sock file for php-fpm
RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.4/fpm/pool.d/www.conf && \
find /etc/php/7.4/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# mycrypt conf
RUN phpenmod mcrypt

# nginx site conf
RUN rm -Rf /etc/nginx/conf.d/* && \
rm -Rf /etc/nginx/sites-available/default && \
rm -Rf /etc/nginx/sites-enabled/default && \
mkdir -p /etc/nginx/ssl/
mkdir -p /etc/php/7.4/mods-available/
ADD conf/nginx-site.conf /etc/nginx/sites-available/default.conf
RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

# Add git commands to allow container updating
ADD scripts/pull /usr/bin/pull
ADD scripts/push /usr/bin/push
RUN chmod 755 /usr/bin/pull 
RUN chmod 755 /usr/bin/push

# Supervisor Config
ADD conf/supervisord.conf /etc/supervisord.conf

# Fix socket file
RUN mkdir -p /run/php/ 
RUN chown -Rf www-data.www-data /run/php

# Start Supervisord
ADD scripts/start.sh /start.sh
RUN chmod 755 /start.sh

# Setup Volume
VOLUME ["/usr/share/nginx/html"]

# add test PHP file
ADD src/index.php /var/www/index.php
RUN chown -Rf www-data.www-data /var/www/

RUN apt-get update
RUN apt-get install -y unzip
RUN apt-get clean -y

# Link the files of timezone.
# Crie um link simbolico do arquivo de fuso horário.
RUN ln -fs /usr/share/zoneinfo/America/Cuiaba /etc/localtime 
RUN apt-get install -y tzdata expect 
RUN dpkg-reconfigure --frontend noninteractive tzdata 

# Oracle instantclient
ADD /files/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip /opt/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip
ADD /files/instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip /opt/instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip
ADD /files/instantclient-sqlplus-linux.x64-19.6.0.0.0dbru.zip /opt/instantclient-sqlplus-linux.x64-19.6.0.0.0dbru.zip
RUN unzip /opt/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip -d /usr/local/ 
RUN unzip /opt/instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip -d /usr/local/ 
RUN unzip /opt/instantclient-sqlplus-linux.x64-19.6.0.0.0dbru.zip -d /usr/local/ 
RUN rm -f /opt/*.zip 
RUN ln -s /usr/local/instantclient_19_6 /usr/local/instantclient 
RUN ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus
# Add the folder to ldconfig.
# Adicione a pasta ao ldconfig.
RUN echo /usr/local/instantclient > /etc/ld.so.conf.d/oracle-instantclient.conf 
# Update the dynamic linker run-time bindings.
# Atualizar as ligações em tempo de execução dos links dinâmicos.
RUN ldconfig 
RUN echo 'instantclient,/usr/local/instantclient' | pecl install oci8
RUN echo "extension=oci8.so" > /etc/php/7.4/mods-available/30-oci8.ini
RUN ln -s /etc/php/7.4/mods-available/30-oci8.ini /etc/php/7.4/cli/conf.d/30-oci8.ini
RUN ln -s /etc/php/7.4/mods-available/30-oci8.ini /etc/php/7.4/fpm/conf.d/30-oci8.ini

# Install the mongodb extension
RUN	apt-get -y install libsasl2-dev

RUN mkdir -p /usr/local/openssl/include/openssl/ && \
    ln -s /usr/include/openssl/evp.h /usr/local/openssl/include/openssl/evp.h && \
    mkdir -p /usr/local/openssl/lib/ && \
    ln -s /usr/lib/x86_64-linux-gnu/libssl.a /usr/local/openssl/lib/libssl.a && \
    ln -s /usr/lib/x86_64-linux-gnu/libssl.so /usr/local/openssl/lib/

# Install vim
RUN apt-get install -y vim
RUN apt-get autoremove -y 
RUN apt-get clean 
RUN apt-get autoclean 

# Expose Ports
EXPOSE 443
EXPOSE 80

# Set default work directory
WORKDIR /var/www

CMD ["/bin/bash", "/start.sh"]