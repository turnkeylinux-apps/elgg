#!/bin/bash
set -Eeuo pipefail
umask 077

result=${TKL_TEST_RESULT:?TKL_TEST_RESULT is required}
app_password=${TKL_TEST_APP_PASS:?TKL_TEST_APP_PASS is required}
base=https://localhost
cookie=/tmp/tkl-elgg-cookie.$$
page=/tmp/tkl-elgg-page.$$
headers=/tmp/tkl-elgg-headers.$$

cleanup() {
    rm -f -- "$cookie" "$page" "$headers"
}
trap cleanup EXIT
trap 'status=$?; echo "Elgg acceptance failed at line $LINENO (status $status)" >&2; exit "$status"' ERR

token_from() {
    local name=$1
    local file=$2
    sed -n "s/.*name=[\"']${name}[\"'][^>]*value=[\"']\([^\"']*\)[\"'].*/\1/p" \
        "$file" | head -n1
}

systemctl --quiet is-active apache2.service mariadb.service postfix.service \
    cron.service
systemctl --quiet is-enabled apache2.service mariadb.service postfix.service \
    cron.service
apache2ctl -t
apache2ctl -M 2>/dev/null | grep -F ' rewrite_module ' >/dev/null
apache2ctl -M 2>/dev/null | grep -F ' ssl_module ' >/dev/null

installed_version=$(php -r '
$data = json_decode(file_get_contents("/var/www/elgg/vendor/composer/installed.json"), true);
foreach (($data["packages"] ?? $data) as $package) {
    if ($package["name"] === "elgg/elgg") { echo $package["version"]; }
}')
test "$installed_version" = 7.0.5

curl --insecure --fail --silent --show-error \
    --cookie "$cookie" --cookie-jar "$cookie" "$base/login" >"$page"
timestamp=$(token_from __elgg_ts "$page")
token=$(token_from __elgg_token "$page")
test -n "$timestamp"
test -n "$token"
curl --insecure --silent --show-error \
    --cookie "$cookie" --cookie-jar "$cookie" \
    --dump-header "$headers" --output "$page" \
    "$base/action/login" \
    --data-urlencode "__elgg_ts=$timestamp" \
    --data-urlencode "__elgg_token=$token" \
    --data-urlencode 'username=admin' \
    --data-urlencode "password=$app_password"
grep -q '^HTTP/.* 302' "$headers"
curl --insecure --fail --silent --show-error \
    --cookie "$cookie" "$base/" >"$page"
grep -Eqi 'logout|Administrator' "$page"

admin_guid=$(mariadb --batch --skip-column-names elgg --execute \
    "SELECT guid FROM elgg_entities WHERE type='user' AND owner_guid=0 LIMIT 1")
test -n "$admin_guid"
curl --insecure --fail --silent --show-error \
    --cookie "$cookie" "$base/blog/add/$admin_guid" >"$page"
timestamp=$(token_from __elgg_ts "$page")
token=$(token_from __elgg_token "$page")
test -n "$timestamp"
test -n "$token"
curl --insecure --silent --show-error \
    --cookie "$cookie" --cookie-jar "$cookie" \
    --dump-header "$headers" --output "$page" \
    "$base/action/blog/edit" \
    --data-urlencode "__elgg_ts=$timestamp" \
    --data-urlencode "__elgg_token=$token" \
    --data-urlencode "container_guid=$admin_guid" \
    --data-urlencode 'title=TurnKey v19 acceptance post' \
    --data-urlencode 'description=Created through the Elgg web interface' \
    --data-urlencode 'status=published' \
    --data-urlencode 'access_id=2' \
    --data-urlencode 'comments_on=On' \
    --data-urlencode 'save=1'
grep -q '^HTTP/.* 302' "$headers"
blog_url=$(sed -n 's|^[Ll]ocation: \(.*\)|\1|p' "$headers" | tr -d '\r' | tail -n1)
test -n "$blog_url"
curl --insecure --fail --silent --show-error \
    --cookie "$cookie" "$blog_url" >"$page"
grep -Fq 'TurnKey v19 acceptance post' "$page"
grep -Fq 'Created through the Elgg web interface' "$page"

password_hash=$(mariadb --batch --skip-column-names elgg --execute \
    "SELECT value FROM elgg_metadata WHERE entity_guid=$admin_guid AND name='password_hash'")
[[ $password_hash == '$2'* ]]
test "$(mariadb --batch --skip-column-names elgg --execute 'SHOW TABLES' | wc -l)" -ge 20

turnkey-elgg-cli cron -q
dpkg-query -W php8.4 php8.4-intl mariadb-server webmin-apache \
    webmin-mysql >/dev/null
curl --insecure --fail --silent --show-error --head \
    https://127.0.0.1:12321/ >/dev/null
ss -ltn | grep -Eq '127\.0\.0\.1:25[[:space:]]'

latest_tag=$(curl --fail --silent --show-error \
    https://api.github.com/repos/Elgg/Elgg/releases/latest |
    sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -n1)
test -n "$latest_tag"
grep -Rqs '^Suites: trixie' /etc/apt/sources.list.d
! grep -Rqi bookworm /etc/apt/sources.list.d

cat >"$result" <<EOF
package_source=Debian 13 Trixie PHP, MariaDB and Apache packages; official complete Elgg 7.0.5 release archive
installed_version=Elgg $installed_version; PHP $(php -r 'echo PHP_VERSION;')
runtime_checks=normal init; Apache TLS; firstboot administrator web login; authenticated blog create and read; MariaDB user and password state; Elgg cron; Webmin and local Postfix
updater_command=turnkey-composer --with-all-dependencies require elgg/elgg:REVIEWED_VERSION followed by turnkey-elgg-cli upgrade async -v
updater_result=official latest release endpoint returned $latest_tag
updater_channel=official Elgg GitHub releases and Composer package metadata
integrity_evidence=build verifies the upstream-published Elgg 7.0.5 archive SHA-256 a369a5b97c22e31998d7ed3e107c410efbcd1d8f3a3edacea4b64af8a3027c10; the complete release includes its resolved dependencies and Composer lock; Debian metadata is signed; no Bookworm source remained
EOF
