-- Prosodyx container configuration
--
-- The served domain is taken from the PROSODYX_DOMAIN environment
-- variable and is required. Certificates are read from
-- /etc/prosody/certs and data is stored under /var/lib/prosody.
-- Check with: prosodyctl check config

local domain = ENV_PROSODYX_DOMAIN
if domain == nil or domain == "" then
	error("PROSODYX_DOMAIN environment variable is not set")
end

admins = { }

modules_enabled = {
		"disco";
		"roster";
		"saslauth";
		"tls";

		"blocklist";
		"bookmarks";
		"carbons";
		"limits";
		"pep";
		"private";
		"smacks";
		"vcard4";
		"vcard_legacy";

		"account_activity";
		"cloud_notify";
		"csi_simple";
		"invites";
		"invites_adhoc";
		"invites_register";
		"ping";
		"register";
		"time";
		"uptime";
		"version";
		"mimicking";
		"tombstones";

		"admin_adhoc";
		"admin_shell";
}

s2s_secure_auth = true

c2s_require_encryption = true
s2s_require_encryption = true

allow_registration = false

disable_sasl_mechanisms = { "PLAIN", "DIGEST-MD5" }

authentication = "internal_hashed"

data_path = "/var/lib/prosody"

admin_socket = "/var/lib/prosody/prosody.sock"

archive_expires_after = "1w"

limits = {
	c2s = {
		rate = "10kb/s";
	};
	s2sin = {
		rate = "30kb/s";
	};
}

c2s_stanza_size_limit = 128 * 1024
s2s_stanza_size_limit = 256 * 1024

c2s_timeout = "2 minutes"
s2s_timeout = 60
c2s_close_timeout = 5
s2s_close_timeout = 5

http_max_content_size = 1024 * 1024

http_interfaces = { "127.0.0.1", "::1" }

network_backend = "epoll"

umask = "027"

daemonize = false
pidfile = false

log = {
	info = "*console";
	error = "*console";
}

certificates = "/etc/prosody/certs"

ssl = {
	protocol = "tlsv1_2+";
	ciphers = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305";
	curveslist = { "X25519", "P-384", "P-256" };
	options = { "no_compression", "no_ticket", "cipher_server_preference", "no_renegotiation" };
}

VirtualHost (domain)
