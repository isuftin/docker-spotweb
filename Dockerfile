FROM phusion/baseimage:0.9.15
MAINTAINER Andy Verbunt <andy@nexar.be>

ENV DEBIAN_FRONTEND noninteractive

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

RUN apt-get update -q

# Install packages
RUN apt-get -y install apache2 php5 php5-curl php5-gd php5-gmp php5-mysql

# Add our crontab file
ADD cron.cfg /root/cron.cfg

# Use the crontab file
RUN crontab /root/cron.cfg

# Start cron
RUN cron

# Enable apache mods
RUN a2enmod php5

# Update the php.ini file
RUN sed -i "s/^;date.timezone =.*/date.timezone = Europe\/Brussels/" /etc/php5/apache2/php.ini

# Install git
RUN apt-get -y install git

# Install spotweb using git
RUN git clone https://github.com/Spotweb/Spotweb.git /var/www/site/spotweb

# Update the default apache site with the config we created
ADD apache-config.conf /etc/apache2/sites-enabled/000-default.conf

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2

RUN mkdir -p $APACHE_RUN_DIR $APACHE_LOCK_DIR $APACHE_LOG_DIR

EXPOSE 80

# Add apache to runit
RUN mkdir /etc/service/apache
ADD apache.sh /etc/service/apache/run
RUN chmod +x /etc/service/apache/run
