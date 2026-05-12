#!/bin/sh
set -eu

# Docker Desktop (macOS/Windows) resolves host.docker.internal as both A and AAAA.
# Xdebug can pick the AAAA first, but many containers don't have IPv6 routes, yielding "Network is unreachable".
# We resolve an IPv4 address (A record) and pass it as a numeric client_host via XDEBUG_CONFIG.

DEFAULT_HOST="${XDEBUG_DEFAULT_CLIENT_HOST:-host.docker.internal}"
RESOLVED_HOST="$(php -r "echo gethostbyname('${DEFAULT_HOST}');" 2>/dev/null || true)"

# If resolution fails, gethostbyname returns the input string; fall back to the original hostname.
if [ -z "${RESOLVED_HOST}" ] || [ "${RESOLVED_HOST}" = "${DEFAULT_HOST}" ]; then
  RESOLVED_HOST="${DEFAULT_HOST}"
fi

XDEBUG_CLIENT_HOST="${XDEBUG_CLIENT_HOST:-${RESOLVED_HOST}}"
XDEBUG_CLIENT_PORT="${XDEBUG_CLIENT_PORT:-9003}"

BASE_XDEBUG_CONFIG="client_host=${XDEBUG_CLIENT_HOST} client_port=${XDEBUG_CLIENT_PORT}"
if [ -n "${XDEBUG_CONFIG:-}" ]; then
  export XDEBUG_CONFIG="${BASE_XDEBUG_CONFIG} ${XDEBUG_CONFIG}"
else
  export XDEBUG_CONFIG="${BASE_XDEBUG_CONFIG}"
fi

# Also write a late-loaded ini file so Xdebug uses a numeric IPv4 client_host even if
# php-fpm scrubs environment variables (common in FPM master/worker setups).
cat > /usr/local/etc/php/conf.d/zz-xdebug-client-host.ini <<EOF
[xdebug]
xdebug.client_host=${XDEBUG_CLIENT_HOST}
xdebug.client_port=${XDEBUG_CLIENT_PORT}
EOF

# Ensure Xdebug log file is writable by the FPM user (www-data). Without this, the php-info page
# will report "File '/tmp/xdebug.log' could not be opened."
mkdir -p /tmp
touch /tmp/xdebug.log || true
chown www-data:www-data /tmp/xdebug.log || true
chmod 0666 /tmp/xdebug.log || true

exec docker-php-entrypoint "$@"

