FROM php:8.2-cli-bookworm

RUN docker-php-ext-install pdo pdo_mysql \
    && mkdir -p /app/backend/storage/encrypted

WORKDIR /app

COPY database ./database
COPY backend ./backend

ENV STORAGE_PATH=/data/encrypted
ENV APP_ENV=production
ENV CORS_ORIGIN=*

EXPOSE 8080

CMD ["sh", "-c", "mkdir -p \"$STORAGE_PATH\" && php backend/scripts/migrate.php && php -d upload_max_filesize=500M -d post_max_size=512M -d memory_limit=512M -d max_execution_time=600 -S 0.0.0.0:${PORT:-8080} -t backend/public backend/public/router.php"]
