FROM composer:2.7 as vendor

WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --optimize-autoloader --no-scripts

# --------------------------------------------------------------------

FROM php:8.2-fpm-alpine

RUN apk add --no-cache nginx supervisor

COPY .docker/nginx.conf /etc/nginx/http.d/default.conf
COPY .docker/supervisord.conf /etc/supervisor/conf.d/app.conf

WORKDIR /app

COPY --chown=www-data:www-data . .
COPY --chown=www-data:www-data --from=vendor /app/vendor/ ./vendor/

RUN chown -R www-data:www-data /app \
    && chmod -R 775 /app/storage /app/bootstrap/cache


EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/app.conf"]
