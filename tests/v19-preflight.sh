#!/bin/bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl unzip \
    mariadb-client mariadb-server php-cli php-curl php-gd php-intl \
    php-mbstring php-mysql php-xml
update-ca-certificates

archive=/tmp/elgg-7.0.5.zip
curl --fail --location \
    https://github.com/Elgg/Elgg/releases/download/7.0.5/elgg-7.0.5.zip \
    --output "$archive"
printf '%s  %s\n' \
    a369a5b97c22e31998d7ed3e107c410efbcd1d8f3a3edacea4b64af8a3027c10 \
    "$archive" | sha256sum --check -

install -d -o www-data -g www-data /var/www/elgg /var/www/elgg-data
unzip -q "$archive" -d /tmp/elgg-release
cp -a /tmp/elgg-release/elgg-7.0.5/. /var/www/elgg/
chown -R www-data:www-data /var/www/elgg

service mariadb start
mariadb --batch --execute \
    "CREATE DATABASE elgg; CREATE USER 'elgg'@'localhost' IDENTIFIED BY 'fixture-db-pass'; GRANT ALL PRIVILEGES ON elgg.* TO 'elgg'@'localhost';"

cat >/tmp/install.php <<'PHP'
<?php
return [
    'timezone' => 'UTC',
    'dataroot' => '/var/www/elgg-data',
    'wwwroot' => 'https://www.example.com/',
    'dbuser' => 'elgg',
    'dbpassword' => 'fixture-db-pass',
    'dbname' => 'elgg',
    'dbhost' => 'localhost',
    'dbport' => '3306',
    'dbprefix' => 'elgg_',
    'sitename' => 'TurnKey Elgg',
    'siteemail' => 'admin@example.invalid',
    'displayname' => 'Administrator',
    'email' => 'admin@example.invalid',
    'username' => 'admin',
    'password' => 'fixture-admin-pass',
];
PHP
chown www-data:www-data /tmp/install.php
runuser -u www-data -- /var/www/elgg/vendor/bin/elgg-cli install \
    --config /tmp/install.php

runuser -u www-data -- /var/www/elgg/vendor/bin/elgg-cli list --raw |
    grep -Eq '^cron([[:space:]]|$)'
version=$(php -r '
$data = json_decode(file_get_contents("/var/www/elgg/vendor/composer/installed.json"), true);
foreach (($data["packages"] ?? $data) as $package) {
    if ($package["name"] === "elgg/elgg") { echo $package["version"]; }
}')
test "$version" = 7.0.5
table_count=$(mariadb --batch --skip-column-names elgg --execute 'SHOW TABLES' | wc -l)
test "$table_count" -ge 20
printf 'elgg_preflight=pass version=%s php=%s tables=%s\n' \
    "$version" "$(php -r 'echo PHP_VERSION;')" "$table_count"
