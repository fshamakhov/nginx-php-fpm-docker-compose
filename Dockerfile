####################################
# PHPDocker.io PHP 7.3 / FPM image #
####################################

FROM phpdockerio/php73-cli

ARG DEBIAN_FRONTEND=noninteractive

# Install FPM
RUN apt-get update \
    && apt-get -y --no-install-recommends install apt-utils \
    && apt-get -y --no-install-recommends install build-essential \
    && apt-get -y --no-install-recommends install php7.3-fpm \
    && apt-get -y --no-install-recommends install php7.3-mbstring \
    && apt-get -y --no-install-recommends install php7.3-mysql \
    && apt-get -y --no-install-recommends install php7.3-gd \
    && apt-get -y --no-install-recommends install php7.3-memcached \
    && apt-get -y --no-install-recommends install php7.3-memcache \
    && apt-get -y --no-install-recommends install php7.3-dev \
    && apt-get -y --no-install-recommends install php7.3-imap \
    && apt-get -y --no-install-recommends install php-xdebug \
    && apt-get -y --no-install-recommends install php-imagick \
    && apt-get -y --no-install-recommends install wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*


RUN wget -O phpunit.phar https://phar.phpunit.de/phpunit-7.phar
RUN chmod +x phpunit.phar
RUN ln -s /phpunit.phar /usr/local/bin/phpunit

# Configure FPM to run properly on docker
RUN sed -i "/listen = .*/c\listen = [::]:9000" /etc/php/7.3/fpm/pool.d/www.conf \
    && sed -i "/;access.log = .*/c\access.log = /proc/self/fd/2" /etc/php/7.3/fpm/pool.d/www.conf \
    && sed -i "/;clear_env = .*/c\clear_env = no" /etc/php/7.3/fpm/pool.d/www.conf \
    && sed -i "/;catch_workers_output = .*/c\catch_workers_output = yes" /etc/php/7.3/fpm/pool.d/www.conf \
    && sed -i "/pid = .*/c\;pid = /run/php/php7.3-fpm.pid" /etc/php/7.3/fpm/php-fpm.conf \
    && sed -i "/;daemonize = .*/c\daemonize = no" /etc/php/7.3/fpm/php-fpm.conf \
    && sed -i "/error_log = .*/c\error_log = /proc/self/fd/2" /etc/php/7.3/fpm/php-fpm.conf \
    && usermod -u 1000 www-data

# Configure FPM Xdebug
RUN echo "xdebug.remote_enable=1" >> /etc/php/7.3/mods-available/xdebug.ini \
    && echo "xdebug.remote_autostart=1" >> /etc/php/7.3/mods-available/xdebug.ini \
    && echo "xdebug.remote_log=xdebug.log" >> /etc/php/7.3/mods-available/xdebug.ini \
    && echo "xdebug.remote_host=host.docker.internal" >> /etc/php/7.3/mods-available/xdebug.ini \
    && echo "xdebug.profiler_enable=0" >> /etc/php/7.3/mods-available/xdebug.ini \
    && echo "xdebug.profiler_enable_trigger=1" >> /etc/php/7.3/mods-available/xdebug.ini \
    && echo "xdebug.profiler_output_dir=/var/www/thebell_admin/storage/logs/profiler/" >> /etc/php/7.3/mods-available/xdebug.ini

RUN mkdir -p /var/www
RUN chown -R www-data:www-data /var/www

# The following runs FPM and removes all its extraneous log output on top of what your app outputs to stdout
CMD /usr/sbin/php-fpm7.3 -F -O 2>&1 | sed -u 's,.*: \"\(.*\)$,\1,'| sed -u 's,"$,,' 1>&1

# Open up fcgi port
EXPOSE 9000

# Добавить в launch.json для XDebug на VSCode (The Bell)
# "pathMappings": {
#     "/var/www/thebell": "${workspaceFolder}"
# }

# Важные конфиги
# /etc/php/7.3/mods-available/xdebug.ini
# /usr/lib/php/20160303/xdebug.so
# /etc/php/7.3/fpm/php.ini

# host.docker.internal на Windows обычно подразумевает 10.0.75.1
