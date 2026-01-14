# Note: Use docker-compose up -d --force-recreate --build when Dockerfile has changed.
# ========================================================

# --------------------------------------------
# Build mhsendmail from source (works on arm64 + amd64)
# --------------------------------------------
FROM golang:1.22-bookworm AS mhsendmail-builder

RUN set -eux; \
    go install github.com/mailhog/mhsendmail@latest

# --------------------------------------------
# PHP-FPM image for WordPress (PHP 8.2)
# --------------------------------------------
FROM php:8.2-fpm-bullseye

# Install OS deps (runtime + build)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ghostscript \
        ca-certificates \
        curl \
        sudo \
        less \
        mariadb-client \
        \
        # imagick runtime + headers
        imagemagick \
        libmagickwand-dev \
        \
        # php extensions deps
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libzip-dev \
    ; \
    rm -rf /var/lib/apt/lists/*

# Install PHP extensions required for WordPress
RUN set -eux; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
        bcmath \
        exif \
        gd \
        mysqli \
        pdo \
        pdo_mysql \
        zip \
    ; \
    pecl install imagick; \
    docker-php-ext-enable imagick

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
RUN set -eux; \
    { \
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
RUN set -eux; \
    pecl install xdebug; \
    docker-php-ext-enable xdebug

# Set up volume for WordPress files
VOLUME /var/www/html

# Install WP-CLI
RUN set -eux; \
    curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
    chmod +x /usr/local/bin/wp; \
    mkdir -p /var/www/.wp-cli/cache; \
    chown -R www-data:www-data /var/www/.wp-cli

# Forward email to Mailhog using mhsendmail (built for the current platform)
COPY --from=mhsendmail-builder /go/bin/mhsendmail /usr/local/bin/mhsendmail
RUN set -eux; \
    chmod +x /usr/local/bin/mhsendmail; \
    echo 'sendmail_path="/usr/local/bin/mhsendmail --smtp-addr=mailhog:1025 --from=no-reply@gbp.lo"' > /usr/local/etc/php/conf.d/mailhog.ini
        