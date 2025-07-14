# Dockerfile

# Stage 1: Install PHP dependencies with Composer
FROM composer:2.7 as vendor

WORKDIR /app
COPY composer.json composer.lock ./
# --no-scripts prevents errors if APP_KEY is not available during build
RUN composer install --no-dev --no-interaction --optimize-autoloader --no-scripts

# --------------------------------------------------------------------

# Stage 2: Setup the final image with Nginx and PHP-FPM
FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
      nginx \
      supervisor \
      icu-dev # NEW: System dependency for the intl extension

# Install PHP extensions
# The intl extension is needed by Filament/Support
RUN docker-php-ext-install intl # NEW: Install the intl extension

# Copy Nginx and Supervisor config files
COPY .docker/nginx.conf /etc/nginx/http.d/default.conf
COPY .docker/supervisord.conf /etc/supervisor/conf.d/app.conf

# Set working directory
WORKDIR /app

# Copy application code and vendor files from the first stage
COPY --chown=www-data:www-data . .
COPY --chown=www-data:www-data --from=vendor /app/vendor/ ./vendor/

# Set correct permissions for Laravel
RUN chown -R www-data:www-data /app \
    && chmod -R 775 /app/storage /app/bootstrap/cache

# Expose port 80 for Nginx
EXPOSE 80

# The command to start all services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/app.conf"]
