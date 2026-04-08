# PHP 8.5 + Apache (Debian Bookworm)
FROM php:8.5-apache

ENV ACCEPT_EULA=Y \
    PATH="$PATH:/opt/mssql-tools/bin"

# System deps + Microsoft ODBC 17 + Apache modules in a single layer
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        gnupg2 \
        libpng-dev \
        libzip-dev \
        unzip \
        curl \
        ca-certificates \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | tee /usr/share/keyrings/microsoft.asc > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/microsoft.asc] https://packages.microsoft.com/debian/12/prod bookworm main" \
        | tee /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        msodbcsql17 \
        mssql-tools \
        unixodbc-dev \
    && a2enmod ssl rewrite \
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
COPY ./config/apache/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./config/ssl/localhost.crt /etc/ssl/certs/localhost.crt
COPY ./config/ssl/localhost.key /etc/ssl/private/localhost.key
COPY ./index.php /var/www/html/

RUN cp /etc/ssl/certs/localhost.crt /usr/local/share/ca-certificates/localhost.crt \
    && update-ca-certificates

WORKDIR /var/www/html
