#!/usr/bin/env bash
# Smoke test for the prosodyx container image.
# Usage: [ENGINE=podman|docker] smoke-test.sh <image>
# Builds a throwaway self-signed certificate, starts the image with a
# read-only root filesystem, and checks startup, TLS policy and the
# health check. Requires podman or docker and openssl on the host.

set -euo pipefail

image=${1:?usage: smoke-test.sh <image>}
name="prosodyx-smoke-$$"
work=$(mktemp -d)
engine=${ENGINE:-$(command -v podman || command -v docker)}

cleanup() {
	"$engine" rm -f "$name" >/dev/null 2>&1 || true
	rm -rf "$work" 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "$work/certs" "$work/data"
openssl req -x509 -newkey rsa:2048 -nodes \
	-keyout "$work/certs/localhost.key" \
	-out "$work/certs/localhost.crt" \
	-days 1 -subj "/CN=localhost" >/dev/null 2>&1
chmod 0644 "$work/certs/localhost.key"

data_opts=Z
if [ "$(basename "$engine")" = docker ]; then
	chmod 0777 "$work/data"
else
	data_opts=U,Z
fi

"$engine" run -d --name "$name" \
	--cap-drop=all --security-opt=no-new-privileges --read-only \
	--tmpfs /tmp:rw,noexec,nosuid,size=16m \
	-e PROSODYX_DOMAIN=localhost \
	-v "$work/certs:/etc/prosody/certs:ro,Z" \
	-v "$work/data:/var/lib/prosody:$data_opts" \
	-p 127.0.0.1:15222:5222 \
	"$image" >/dev/null

ok() { echo "PASS: $1"; }
die() { echo "FAIL: $1" >&2; exit 1; }

"$engine" exec "$name" /usr/bin/lua5.4 /usr/bin/prosodyctl check config >/dev/null 2>&1 \
	|| die "prosodyctl check config failed"
ok "prosodyctl check config"

for _ in $(seq 1 30); do
	if "$engine" exec "$name" /usr/bin/lua5.4 /etc/prosody/healthcheck.lua >/dev/null 2>&1; then
		break
	fi
	sleep 1
done
"$engine" exec "$name" /usr/bin/lua5.4 /etc/prosody/healthcheck.lua \
	|| die "healthcheck failed"
ok "healthcheck"

tls_connect() {
	echo Q | openssl s_client -connect 127.0.0.1:15222 \
		-starttls xmpp -xmpphost localhost "$@" 2>/dev/null
}

tls_connect -tls1_3 | grep -q "Cipher is TLS_" || die "TLS 1.3 connect failed"
ok "TLS 1.3"

tls_connect -tls1_2 | grep -q "Cipher is ECDHE-" || die "TLS 1.2 connect failed"
ok "TLS 1.2"

if tls_connect -tls1_1 -cipher 'ALL:@SECLEVEL=0' | grep -q "Cipher is"; then
	die "TLS 1.1 was not rejected"
else
	ok "TLS 1.1 rejected"
fi

features=$(printf '<stream:stream xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" to="localhost" version="1.0">' | timeout 5 nc 127.0.0.1 15222 | head -c 4096 || true)
case "$features" in
	*"<mechanism>PLAIN</mechanism>"*) die "SASL PLAIN offered before TLS" ;;
	*"required"*) ok "STARTTLS required, no cleartext SASL PLAIN" ;;
	*) die "unexpected stream features" ;;
esac

echo "All smoke checks passed"
