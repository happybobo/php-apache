# build a docker image based on php:5.6-fpm
# add some php extensions

FROM php:5.6-fpm

# replace mirror url to accelerate
RUN echo "deb http://mirrors.163.com/debian/ jessie main\n\
deb http://mirrors.163.com/debian/ jessie-updates main\n\
deb http://mirrors.163.com/debian-security/ jessie/updates main" > /etc/apt/sources.list

# install or enable some extensions
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
        libxml2-dev \
        --no-install-recommends \
    && docker-php-ext-install -j"$(nproc)" mcrypt exif bcmath gettext hash pcntl shmop sockets sysvsem xmlrpc zip mysqli \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j"$(nproc)" gd \
    && rm -r /var/lib/apt/lists/*

# install memcached ext
RUN apt-get update && apt-get install -y libmemcached-dev --no-install-recommends \
    && pecl install memcached \
    && docker-php-ext-enable memcached \
    && rm -r /var/lib/apt/lists/*

# download and install redis ext
RUN curl -fsSL 'https://pecl.php.net/get/redis-2.2.8.tgz' -o redis.tgz \
    && mkdir -p redis \
    && tar -xf redis.tgz -C redis --strip-components=1 \
    && rm redis.tgz \
    && ( \
        cd redis \
        && phpize \
        && ./configure \
        && make -j"$(nproc)" \
        && make install \
    ) \
    && rm -r redis \
    && docker-php-ext-enable redis

# donwload and install zend-loader ext
RUN curl -fsSL 'http://downloads.zend.com/guard/7.0.0/zend-loader-php5.6-linux-x86_64.tar.gz' -o zend-loader.tar.gz \
    && mkdir -p zend-loader \
    && tar -xf zend-loader.tar.gz -C zend-loader --strip-components=1 \
    && rm zend-loader.tar.gz \
    && cp zend-loader/ZendGuardLoader.so /usr/local/lib/php/extensions/no-debug-non-zts-20131226/ \
    && cp zend-loader/opcache.so /usr/local/lib/php/extensions/no-debug-non-zts-20131226/ \
    && rm -r zend-loader \
    && echo "[Zend Guard Loader]\n\
zend_extension=ZendGuardLoader.so\n\
zend_extension=opcache.so\n\
zend_loader.enable=1\n\
zend_loader.disable_licensing=0\n\
zend_loader.obfuscation_level_support=3\n\
;zend_loader.license_path=" > /usr/local/etc/php/conf.d/ZendGuardLoader.ini