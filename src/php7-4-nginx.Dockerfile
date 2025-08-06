# Use PHP 7.4 with FPM on Debian Bullseye
FROM php:7.4-fpm-bullseye

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
    nginx \
    supervisor \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Configure Portuguese (Brazil) locale with ISO-8859-1 for legacy compatibility
RUN sed -i '/^#.*pt_BR.ISO-8859-1/s/^#//' /etc/locale.gen \
    && sed -i '/^#.*pt_BR.UTF-8/s/^#//' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=pt_BR.ISO-8859-1 LC_ALL=pt_BR.ISO-8859-1

# Set locale environment variables for Windows-like charset behavior
ENV LANG=pt_BR.ISO-8859-1
ENV LC_ALL=pt_BR.ISO-8859-1
ENV LC_CTYPE=pt_BR.ISO-8859-1
ENV LANGUAGE=pt_BR:pt:en

# Install Microsoft ODBC Driver for Debian 11 (Bullseye)
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | tee /usr/share/keyrings/microsoft.asc > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/microsoft.asc] https://packages.microsoft.com/debian/11/prod bullseye main" | tee /etc/apt/sources.list.d/mssql-release.list \
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

# Copy configuration files
COPY ./config/odbc/odbcinst17.ini /etc/odbcinst.ini
COPY ./config/php/99-custom_overrides.ini /usr/local/etc/php/conf.d/99-custom_overrides.ini
COPY ./config/nginx/default.conf /etc/nginx/sites-available/default
COPY ./config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy SSL certificates
COPY ./config/ssl/localhost.crt /etc/ssl/certs/localhost.crt
COPY ./config/ssl/localhost.key /etc/ssl/private/localhost.key

# Create necessary directories and enable nginx site
RUN mkdir -p /var/log/nginx /var/log/supervisor /run/nginx \
    && ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default \
    && rm -f /etc/nginx/sites-enabled/default.conf \
    && nginx -t

# Copy application files
COPY ./index.php /var/www/html/

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Set working directory
WORKDIR /var/www/html

# Expose ports
EXPOSE 80 443

# Start supervisor to manage nginx and php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
