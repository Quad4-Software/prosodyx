# syntax=docker/dockerfile:1

ARG WOLFI_BASE=cgr.dev/chainguard/wolfi-base:latest@sha256:88a20e2d017bd20cdc0cb3910de603e7bea9512a6c351a8dd3c9df212ab03d73
ARG RUNTIME_BASE=cgr.dev/chainguard/glibc-dynamic:latest@sha256:709673274b417a48f56374da8a7633ef7b2f5b27e34612ce98a335737318cc94

FROM ${WOLFI_BASE} AS builder

ARG SOURCE_DATE_EPOCH

RUN apk add --no-cache \
	build-base \
	ca-certificates-bundle \
	curl \
	expat-dev \
	icu-dev \
	lua5.4 \
	lua5.4-dev \
	openssl-dev

WORKDIR /build
COPY deps.lock scripts/fetch-deps.sh ./
RUN sh fetch-deps.sh deps.lock /build/deps

ENV HARDEN_CFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=3"
ENV HARDEN_LDFLAGS="-Wl,-z,relro,-z,now"

RUN set -eu; \
	ver() { awk -F'\t' -v n="$1" '$1==n { print $2 }' /build/deps.lock; }; \
	\
	cd /build/deps/luasocket-$(ver luasocket); \
	make -C src linux LUAV=5.4 \
		LUAINC_linux=/usr/include/lua5.4 \
		CC_linux="gcc" \
		CFLAGS_linux="-I/usr/include/lua5.4 -DLUASOCKET_ -Wall -Wshadow -Wextra -Wimplicit $HARDEN_CFLAGS -fPIC" \
		LDFLAGS_linux="$HARDEN_LDFLAGS -shared -fPIC -o"; \
	make -C src install-unix LUAV=5.4 prefix=/usr DESTDIR=/rootfs; \
	\
	cd /build/deps/luaexpat-$(ver luaexpat); \
	make lib LUA_INC="-I/usr/include/lua5.4" \
		CFLAGS="$HARDEN_CFLAGS" LDFLAGS="$HARDEN_LDFLAGS"; \
	make install LUA_V=5.4 DESTDIR=/rootfs; \
	\
	cd /build/deps/luafilesystem-$(ver luafilesystem); \
	make lib LUA_VERSION=5.4 \
		LUA_INC="-I/usr/include/lua5.4" \
		WARN="-Wall -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings -pedantic -fPIC $HARDEN_CFLAGS"; \
	make install LUA_VERSION=5.4 PREFIX=/usr DESTDIR=/rootfs; \
	\
	cd /build/deps/luasec-$(ver luasec); \
	make linux \
		INC_PATH="-I/usr/include/lua5.4" \
		LNX_CFLAGS="$HARDEN_CFLAGS -fPIC -Wall -pedantic -I. -I/usr/include/lua5.4 -DWITH_LUASOCKET" \
		LNX_LDFLAGS="$HARDEN_LDFLAGS -fPIC -shared -L./luasocket"; \
	make install LUAPATH=/rootfs/usr/share/lua/5.4 LUACPATH=/rootfs/usr/lib/lua/5.4

COPY . /src/prosodyx
RUN cd /src/prosodyx && ./configure \
		--prefix=/usr \
		--sysconfdir=/etc/prosody \
		--datadir=/var/lib/prosody \
		--lua-version=5.4 \
		--lua-suffix=5.4 \
		--runwith=/usr/bin/lua5.4 \
		--idn-library=icu \
		--with-random=getrandom \
		--no-example-certs \
		--add-cflags="$HARDEN_CFLAGS" \
		--add-ldflags="$HARDEN_LDFLAGS" && \
	make -j"$(nproc)" && \
	make install DESTDIR=/rootfs && \
	sed -i '1s|.*|#!/usr/bin/lua5.4|' /rootfs/usr/bin/prosody /rootfs/usr/bin/prosodyctl

RUN set -eu; \
	apk add --root /rootfs --initdb --no-cache \
		--repositories-file /etc/apk/repositories \
		--keys-dir /etc/apk/keys \
		lua5.4 \
		libexpat1 \
		openssl \
		icu \
		ca-certificates-bundle; \
	mkdir -p /rootfs/var/lib/prosody /rootfs/etc/prosody/certs /rootfs/tmp; \
	chown -R 65532:65532 /rootfs/var/lib/prosody /rootfs/etc/prosody /rootfs/tmp; \
	chmod 1777 /rootfs/tmp; \
	cp /src/prosodyx/docker/prosody.cfg.lua /rootfs/etc/prosody/prosody.cfg.lua; \
	cp /src/prosodyx/docker/healthcheck.lua /rootfs/etc/prosody/healthcheck.lua; \
	if [ -n "${SOURCE_DATE_EPOCH:-}" ]; then \
		find /rootfs -exec touch -h -d "@${SOURCE_DATE_EPOCH}" {} +; \
	fi

FROM ${RUNTIME_BASE}

ARG VERSION=dev
ARG REVISION=unknown
ARG CREATED=1970-01-01T00:00:00Z

LABEL org.opencontainers.image.title="prosodyx" \
	org.opencontainers.image.description="Hardened Prosody XMPP server" \
	org.opencontainers.image.source="https://github.com/Quad4-Software/prosodyx" \
	org.opencontainers.image.version="${VERSION}" \
	org.opencontainers.image.revision="${REVISION}" \
	org.opencontainers.image.created="${CREATED}" \
	org.opencontainers.image.licenses="MIT"

COPY --from=builder /rootfs /

EXPOSE 5222 5269

VOLUME ["/var/lib/prosody"]

USER 65532:65532

STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
	CMD ["/usr/bin/lua5.4", "/etc/prosody/healthcheck.lua"]

ENTRYPOINT ["/usr/bin/prosody", "-F"]
