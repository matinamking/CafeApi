# از یک ایمیج پایه رسمی PHP با PHP-FPM و سیستم‌عامل سبک Alpine استفاده می‌کنیم
FROM php:8.2-fpm-alpine

# نیازمندی‌های سیستمی را نصب می‌کنیم
# Nginx برای وب سرور، Supervisor برای مدیریت پروسه‌ها،
# Composer برای وابستگی‌های PHP، و بقیه برای اکستنشن‌های PHP
RUN apk add --no-cache \
      nginx \
      supervisor \
      composer \
      git \
      zip \
      unzip \
      icu-dev \
      libpng-dev \
      jpeg-dev \
      freetype-dev

# اکستنشن‌های مورد نیاز لاراول و Filament را نصب می‌کنیم
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
      gd \
      bcmath \
      pdo_mysql \
      opcache \
      exif \
      zip \
      intl

# فایل‌های کانفیگ Nginx و Supervisor را کپی می‌کنیم
# مطمئن شوید پوشه .docker و این فایل‌ها را ساخته‌اید
COPY .docker/nginx.conf /etc/nginx/http.d/default.conf
COPY .docker/supervisord.conf /etc/supervisor/conf.d/app.conf

# مسیر کاری را تنظیم می‌کنیم
WORKDIR /app

# فایل‌های پروژه را کپی می‌کنیم
COPY . .

# وابستگی‌های PHP را با Composer نصب می‌کنیم
# این بار بعد از اینکه همه چیز آماده است
RUN composer install --no-dev --no-interaction --optimize-autoloader

# دسترسی‌های صحیح را برای پوشه‌های لاراول تنظیم می‌کنیم
RUN chown -R www-data:www-data /app \
    && chmod -R 775 /app/storage /app/bootstrap/cache

# پورت 80 را برای Nginx باز می‌کنیم
EXPOSE 80

# سرویس‌ها را با Supervisor اجرا می‌کنیم
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/app.conf"]
