#!/bin/bash

# Настройки
APP_NAME="testcicd.reslab.pro"  # Замените на имя вашего приложения
APP_PATH="/var/www/$APP_NAME"
RELEASES_PATH="$APP_PATH/releases"
CURRENT_PATH="$APP_PATH/public_html"
SHARED_PATH="$APP_PATH/shared"
REPO_URL="git@github.com:andrewchuev/testcicd.git"  # Замените на ваш URL репозитория
KEEP_RELEASES=5  # Сколько последних релизов хранить

# 1. Создание новой директории релиза
TIMESTAMP=$(date +%Y%m%d%H%M%S)
RELEASE_PATH="$RELEASES_PATH/$TIMESTAMP"
echo "Deploying to $RELEASE_PATH"

# 2. Клонирование репозитория
git clone --depth 1 "$REPO_URL" "$RELEASE_PATH"

# Выход если клонирование не удалось
if [ $? -ne 0 ]; then
  echo "Git clone failed."
  exit 1
fi

# 3. Установка зависимостей
cd "$RELEASE_PATH"
composer install --no-dev --optimize-autoloader

# Выход если установка зависимостей не удалась
if [ $? -ne 0 ]; then
   echo "Composer install failed."
   exit 1
fi

# 4. Создание/обновление символических ссылок
ln -s "$SHARED_PATH/.env" "$RELEASE_PATH/.env"
ln -s "$SHARED_PATH/storage" "$RELEASE_PATH/storage"
#  Создайте директорию storage, если она не существует:
 if [ ! -d "$SHARED_PATH/storage" ]; then
     mkdir -p "$SHARED_PATH/storage/app/public"
     mkdir -p "$SHARED_PATH/storage/framework/{sessions,views,cache/data}"
     chown -R testcicd:testcicd "$SHARED_PATH/storage"
     chmod -R 775 "$SHARED_PATH/storage" # Или более строгие права, если необходимо
 fi

# 5. Миграции базы данных
php artisan migrate --force

# Выход, если миграции не выполнились
if [ $? -ne 0 ]; then
  echo "Database migration failed."
  exit 1
fi

# 6. Очистка кэша
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 7. Обновление символической ссылки current
ln -sfn "$RELEASE_PATH" "$CURRENT_PATH"

# 8. Перезапуск PHP-FPM
sudo systemctl restart php8.3-fpm

# 9. Очистка старых релизов
cd "$RELEASES_PATH"
ls -t | tail -n +"$((KEEP_RELEASES + 1))" | xargs -I {} rm -rf {}

echo "Deployment completed successfully!"
exit 0
