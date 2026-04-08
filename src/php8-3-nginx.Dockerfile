# PHP 8.3 + FPM + Nginx (Debian Bookworm)
FROM php:8.3-fpm

ENV ACCEPT_EULA=Y \
    PATH="$PATH:/opt/mssql-tools/bin" \
    LANG=pt_BR.ISO-8859-1 \
    LC_ALL=pt_BR.ISO-8859-1 \
    LC_CTYPE=pt_BR.ISO-8859-1 \
    LANGUAGE=pt_BR:pt:en

# System deps + locale + Microsoft ODBC 17 + Nginx setup in a single layer
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        gnupg2 \
        libpng-dev \
        libzip-dev \
        unzip \
        curl \
        nginx \
        supervisor \
        locales \
        ca-certificates \
    && sed -i '/^#.*pt_BR.ISO-8859-1/s/^#//' /etc/locale.gen \
    && sed -i '/^#.*pt_BR.UTF-8/s/^#//' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=pt_BR.ISO-8859-1 LC_ALL=pt_BR.ISO-8859-1 \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | tee /usr/share/keyrings/microsoft.asc > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/microsoft.asc] https://packages.microsoft.com/debian/12/prod bookworm main" \
        | tee /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        msodbcsql17 \
        mssql-tools \
        unixodbc-dev \
    && mkdir -p /var/log/nginx /var/log/supervisor /run/nginx \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions + Xdebug
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/install-php-extensions
RUN chmod uga+x /usr/bin/install-php-extensions && sync \
    && install-php-extensions \
        bcmath exif gd imagick intl opcache pcntl pdo_sqlsrv redis sqlsrv zip odbc \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug

COPY ./config/odbc/odbcinst17.ini /etc/odbcinst.ini
COPY ./config/php/99-custom_overrides.ini /usr/local/etc/php/conf.d/99-custom_overrides.ini
COPY ./config/nginx/default.conf /etc/nginx/sites-available/default
COPY ./config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./config/ssl/localhost.crt /etc/ssl/certs/localhost.crt
COPY ./config/ssl/localhost.key /etc/ssl/private/localhost.key
COPY ./index.php /var/www/html/

RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default \
    && rm -f /etc/nginx/sites-enabled/default.conf \
    && nginx -t \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && cp /etc/ssl/certs/localhost.crt /usr/local/share/ca-certificates/localhost.crt \
    && update-ca-certificates

WORKDIR /var/www/html
EXPOSE 80 443
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
