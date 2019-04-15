FROM ubuntu:16.04
MAINTAINER Derilinx

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Let the conatiner know that there is no tty
# required by PHP 5.6
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get install -y language-pack-en-base &&\
    export LC_ALL=en_US.UTF-8 && \
    export LANG=en_US.UTF-8


RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y software-properties-common
#RUN DEBIAN_FRONTEND=noninteractive LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php
 
# Basic Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server mysql-client pwgen python-setuptools curl git unzip

# Moodle Requirements
RUN DEBIAN_FRONTEND=noninteractive \
     apt-get -y install apache2 postfix wget supervisor vim curl libcurl3 libcurl3-dev

#RUN DEBIAN_FRONTEND=noninteractive \
    #apt-get install -y python-software-properties
#RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
#RUN apt-get update -y

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
    php php-mbstring php-mcrypt php-mysql php-xml php-gd libapache2-mod-php php-zip php-pgsql php-curl php-xmlrpc php-intl

# SSH
RUN apt-get -y install openssh-server
RUN mkdir -p /var/run/sshd

# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
RUN echo "[mysqld]" >> /etc/mysql/my.cnf
RUN echo "bind-address = 0.0.0.0" >> /etc/mysql/my.cnf

RUN mkdir -p /var/run/mysqld
RUN chown mysql:mysql /var/run/mysqld

RUN easy_install supervisor
ADD ./start.sh /start.sh
ADD ./foreground.sh /etc/apache2/foreground.sh
ADD ./supervisord.conf /etc/supervisord.conf

#ADD https://download.moodle.org/moodle/moodle-latest.tgz /var/www/moodle-latest.tgz
COPY ./moodle-latest.tgz /var/www/moodle-latest.tgz
RUN cd /var/www; tar zxvf moodle-latest.tgz; mv /var/www/moodle /var/www/html
RUN chown -R www-data:www-data /var/www/html/moodle
RUN mkdir /var/moodledata
VOLUME /var/moodledata
VOLUME /var/lib/mysql
RUN chown -R www-data:www-data /var/moodledata; chmod 777 /var/moodledata
RUN chown -R mysql:mysql /var/lib/mysql /var/run/mysqld
RUN chmod 755 /start.sh /etc/apache2/foreground.sh

EXPOSE 80
CMD ["/bin/bash", "/start.sh"]
