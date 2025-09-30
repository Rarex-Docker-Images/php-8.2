FROM php:8.2-fpm AS base

ARG user=dev
ARG uid=1000
ARG APP_VERSION=1.0.0
ARG BUILD_DATE

LABEL org.opencontainers.image.title="php-8.2-fpm" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.description="PHP-FPM 8.2 for development" \
      org.opencontainers.image.authors="rarex.dew@gmail.com" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      maintainer="rarex.dew@gmail.com"

RUN apt-get update && apt-get install -y \
    git curl libpng-dev libjpeg-dev libfreetype6-dev \
    libonig-dev libxml2-dev zip unzip libcurl4-openssl-dev libicu-dev libzip-dev libwebp-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install -j$(nproc) gd pdo_mysql mbstring exif pcntl bcmath opcache curl calendar intl xml zip

RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

COPY ./php/php.ini /usr/local/etc/php/conf.d/zz-10-custom.ini

# Fix FPM warnings
RUN for config in /usr/local/etc/php-fpm.d/*.conf; do \
    if [ -f "$config" ]; then \
        sed -i '/^user = /d; /^group = /d' "$config"; \
    fi; \
done

COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

RUN groupmod -g 1000 www-data && \
    useradd -u ${uid} -g www-data -G root -d /home/${user} -s /bin/bash ${user} && \
    mkdir -p /home/${user}/.composer /var/www && \
    chown -R ${user}:www-data /home/${user} /var/www && \
    chmod 755 /home/${user} /var/www && \
    chmod 750 /home/${user}/.composer

WORKDIR /var/www

# Development stage
FROM base AS dev

LABEL stage="dev"

USER ${user}

# Debug stage
FROM base AS debug

LABEL stage="debug"

RUN pecl install xdebug-3.4.5 && docker-php-ext-enable xdebug

COPY ./php/php.debug.ini /usr/local/etc/php/conf.d/zz-20-debug.ini

USER ${user}