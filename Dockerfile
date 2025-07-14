COPY . /app/.
RUN  mkdir -p /var/log/nginx && mkdir -p /var/cache/nginx

RUN chmod +x $(which composer)


RUN  composer install --ignore-platform-reqs

RUN  npm ci
