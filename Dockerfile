# Use a PHP base image with PHP 8.1
FROM php:8.1-fpm

# Install persistent dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ghostscript \
    ; \
    rm -rf /var/lib/apt/lists/*

# Install PHP extensions required for WordPress
RUN set -ex; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg-dev \
        libmagickwand-dev \
        libpng-dev \
        libzip-dev \
    ; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j "$(nproc)" \
        bcmath \
        exif \
        gd \
        mysqli \
        zip \
    ; \
    pecl install imagick-3.7.0; \
    docker-php-ext-enable imagick; \
    \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { print $3 }' \
        | sort -u \
        | xargs -r dpkg-query -S \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

# Set recommended PHP.ini settings for opcache
RUN set -eux; \
    docker-php-ext-enable opcache; \
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Configure error handling and logging
RUN { \
    echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
    echo 'display_errors = Off'; \
    echo 'display_startup_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_log = /dev/stderr'; \
    echo 'log_errors_max_len = 1024'; \
    echo 'ignore_repeated_errors = On'; \
    echo 'ignore_repeated_source = Off'; \
    echo 'html_errors = Off'; \
} > /usr/local/etc/php/conf.d/error-logging.ini

# Install and configure Xdebug
RUN pecl install xdebug; \
    docker-php-ext-enable xdebug; \
    { \
        echo '[xdebug]'; \
        echo 'xdebug.mode = debug'; \
        echo 'xdebug.start_with_request = trigger'; \
        echo 'xdebug.client_port = 9003'; \
        echo 'xdebug.client_host = host.docker.internal'; \
        echo 'xdebug.log = /tmp/xdebug.log'; \
        echo 'xdebug.connect_timeout_ms = 600'; \
    } > /usr/local/etc/php/conf.d/xdebug.ini

# Set the WordPress version and SHA256 hash
# ENV WORDPRESS_VERSION 6.3.1
# ENV WORDPRESS_SHA1 e1b6477a99595fd72405645c0ad77e10c9337c3d

# OLD:
# ENV WORDPRESS_SHA1 7a5a6d0591771e730b05c49d0c3fc134624d0491

# Install WordPress
# RUN set -ex; \
#     curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"; \
#     echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c -; \
#     tar -xzf wordpress.tar.gz -C /usr/src/; \
#     rm wordpress.tar.gz; \
#     chown -R www-data:www-data /usr/src/wordpress; \
#     mkdir wp-content; \
#     for dir in /usr/src/wordpress/wp-content/*/; do \
#         dir="$(basename "${dir%/}")"; \
#         mkdir "wp-content/$dir"; \
#     done; \
#     chown -R www-data:www-data wp-content; \
#     chmod -R 755 wp-content; \

# Set up volume for WordPress files
VOLUME /var/www/html

# Install WP-CLI
RUN apt-get update && apt-get install -y sudo less mariadb-client
RUN curl -o /bin/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x /bin/wp-cli.phar
RUN cd /bin && mv wp-cli.phar wp
RUN mkdir -p /var/www/.wp-cli/cache && chown www-data:www-data /var/www/.wp-cli/cache

# Forward email to Mailhog
RUN curl --location --output /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 && \
    chmod +x /usr/local/bin/mhsendmail
RUN echo 'sendmail_path="/usr/local/bin/mhsendmail --smtp-addr=mailhog:1025 --from=no-reply@gbp.lo"' > /usr/local/etc/php/conf.d/mailhog.ini

# Note: Use docker-compose up -d --force-recreate --build when Dockerfile has changed.