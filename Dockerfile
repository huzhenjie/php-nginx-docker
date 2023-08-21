FROM php:7.2.34-fpm-alpine
LABEL MAINTAINER="Summer huzhenjie.dev@gmail.com"
ENV TZ "Asia/Shanghai"
ENV TERM xterm
# 默认关闭opcode
ENV OPCODE 0

ADD ./lib/repositories /etc/apk/repositories
ADD ./lib/nginx.conf /
ADD ./lib/index.html /
ADD ./lib/run.sh /

COPY ./lib/conf.d/ $PHP_INI_DIR/conf.d/
COPY ./lib/composer.phar /usr/local/bin/composer
COPY ./lib/www.conf /usr/local/etc/php-fpm.d/www.conf
# 创建www用户
RUN addgroup -g 1000 -S www && adduser -s /sbin/nologin -S -D -u 1000 -G www www
# 配置阿里云镜像源，加快构建速度
RUN sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories

# PHPIZE_DEPS 包含 gcc g++ 等编译辅助类库，完成编译后删除
RUN apk add --no-cache $PHPIZE_DEPS \
    && apk add --no-cache libstdc++ libzip-dev vim\
    && apk update \
    && apk add nginx \
    && pecl install redis-5.3.4 \
    && pecl install zip \
    && pecl install https://pecl.php.net/get/swoole-4.8.13.tgz \
    && docker-php-ext-enable redis zip swoole\
    && apk del $PHPIZE_DEPS
# docker-php-ext-install 指令已经包含编译辅助类库的删除逻辑
RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev \
    && apk update \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && docker-php-ext-install -j$(nproc) opcache \
    && docker-php-ext-install -j$(nproc) bcmath \
    && docker-php-ext-install -j$(nproc) mysqli \
    && chmod +x /usr/local/bin/composer \
    && mkdir /run/nginx \
    && mv /nginx.conf /etc/nginx/conf.d \
    && mv /index.html /var/www/html \
    && touch /run/nginx/nginx.pid \
    && chmod 755 /run.sh

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
EXPOSE 80
EXPOSE 8123
EXPOSE 9000
ENTRYPOINT ["/run.sh"]
