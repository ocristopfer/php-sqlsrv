# Use PHP 7.4 with Apache on Debian Buster
FROM php:7.4-apache-buster

# Set environment variables
ENV ACCEPT_EULA=Y

# Install system dependencies and prerequisites
RUN apt-get update \
    && apt-get install -y \
    apt-transport-https \
    gnupg2 \
    libpng-dev \
    libzip-dev \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Microsoft ODBC Driver for Debian 10 (Buster)
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | tee /usr/share/keyrings/microsoft.asc > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/microsoft.asc] https://packages.microsoft.com/debian/10/prod buster main" | tee /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && apt-get install -y \
    msodbcsql17 \
    mssql-tools \
    unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extension installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/install-php-extensions

# Install PHP extensions
RUN chmod uga+x /usr/bin/install-php-extensions \
    && sync \
    && install-php-extensions \
    bcmath \
    exif \
    gd \
    imagick \
    intl \
    opcache \
    pcntl \
    pdo_sqlsrv \
    redis \
    sqlsrv \
    zip \
    odbc

# Install Xdebug (compatible version for PHP 7.4)
RUN pecl install xdebug-3.1.6 \
    && docker-php-ext-enable xdebug

# Enable Apache modules
RUN a2enmod ssl \
    && a2enmod rewrite

# Copy configuration files
COPY ./config/odbc/odbcinst.ini /etc/odbcinst.ini
COPY ./config/php/99-custom_overrides.ini /usr/local/etc/php/conf.d/99-custom_overrides.ini
COPY ./config/apache/000-default.conf /etc/apache2/sites-available/000-default.conf

# Copy SSL certificates
COPY ./config/ssl/localhost.crt /etc/ssl/certs/localhost.crt
COPY ./config/ssl/localhost.key /etc/ssl/private/localhost.key

# Copy application files
COPY ./index.php /var/www/html/

# Set working directory
WORKDIR /var/www/html
