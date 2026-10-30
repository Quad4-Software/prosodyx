# Deviations from upstream Prosody 13.0.7

This file lists every intentional difference between prosodyx and the
upstream 13.0.7 release.

## Removed modules

Deleted under plugins/:

- mod_admin_telnet, plaintext admin console
- mod_auth_insecure, plaintext credential storage
- mod_auth_internal_plain, plaintext credential storage
- mod_auth_ldap, unauthenticated LDAP binds
- mod_debug_reset, test-only state reset
- mod_debug_sql, SQL debugging
- mod_debug_stanzas (the module itself was removed, the shared
  watcher.lib.lua library stays because mod_admin_shell requires it)
- mod_legacyauth, pre-SASL authentication
- mod_scansion_record, test recorder
- mod_stanza_debug, stanza logging
- mod_storage_xep0227, account import/export
- mod_windows, Windows-only integration

References in GNUmakefile, makefile, util/prosodyctl/check.lua,
tools/ejabberd2prosody.lua and spec/scansion/prosody.cfg.lua were
removed to match.

## Configuration defaults

prosody.cfg.lua.dist and docker/prosody.cfg.lua differ from upstream:

- dialback removed from modules_enabled
- mimicking and tombstones enabled
- register kept enabled so accounts can change passwords, but
  allow_registration = false disables in-band registration
- c2s_require_encryption = true
- s2s_require_encryption = true
- s2s_secure_auth = true (unchanged default)
- disable_sasl_mechanisms = { "PLAIN", "DIGEST-MD5" }
- c2s_stanza_size_limit = 128 KiB (upstream default 256 KiB)
- s2s_stanza_size_limit = 256 KiB (upstream default 512 KiB)
- c2s_timeout = 2 minutes (upstream default 5)
- s2s_timeout = 60 s (upstream default 90)
- c2s_close_timeout = 5 s, s2s_close_timeout = 5 s
- http_max_content_size = 1 MiB
- http_interfaces bound to 127.0.0.1 and ::1
- network_backend = "epoll"
- umask = "027"
- pidfile = false
- ssl: protocol tlsv1_2+, ECDHE AEAD-only cipher list, curves
  X25519/P-384/P-256, no_compression, no_ticket,
  cipher_server_preference, no_renegotiation
- log: info and error to *console only
- docker/prosody.cfg.lua additionally reads PROSODYX_DOMAIN from the
  environment and refuses to start without it, stores data under
  /var/lib/prosody, and reads certificates from /etc/prosody/certs

## Container properties

- Multi-stage build: Wolfi builder, Chainguard glibc-dynamic runtime
- No shell, no package manager, no /usr/bin/env dependency
- Runs as uid:gid 65532:65532
- Only runtime packages installed (apk database retained for scanners)
- Read-only root filesystem supported, tmpfs /tmp, writable
  /var/lib/prosody data volume and read-only /etc/prosody/certs
- Exposes 5222 and 5269, STOPSIGNAL SIGTERM, foreground entrypoint
- HEALTHCHECK via docker/healthcheck.lua (TCP connect to 127.0.0.1:5222)

## Build hardening

- CFLAGS: -O2 -fstack-protector-strong -D_FORTIFY_SOURCE=3
- LDFLAGS: -Wl,-z,relro,-z,now
- --with-random=getrandom
- --runwith absolute path, shebang rewritten to /usr/bin/lua5.4
- --no-example-certs
- Lua dependencies built from sha256-verified release tarballs
  (deps.lock): luasocket 3.1.0, luaexpat 1.5.2, luafilesystem 1.9.0,
  luasec 1.3.2
- SOURCE_DATE_EPOCH honored for reproducible output
