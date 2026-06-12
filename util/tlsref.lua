local array = require "prosody.util.array";
local it = require "prosody.util.iterators";
local version_compare = require "prosody.util.human.io".simple_version_compare;

local latest_version = "6.0"
local default_version = "5.7";
local default_profile = "intermediate"; -- should exist in all profiles

-- https://datatracker.ietf.org/doc/html/rfc7919#appendix-A.1
local ffdhe2048 = [[
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
-----END DH PARAMETERS-----
]];

local profiles = {
	-- https://wiki.mozilla.org/Security/Server_Side_TLS
	["6.0"] = {
		-- Version 6.0 as of 2026-04-08
		modern = {
			protocol = "tlsv1_3";
			options = { cipher_server_preference = false };
			ciphers = "DEFAULT"; -- TLS 1.3 uses 'ciphersuites' rather than these
			curveslist = { "X25519MLKEM768"; "X25519"; "prime256v1"; "secp384r1" };
			ciphersuites = { "TLS_AES_128_GCM_SHA256"; "TLS_AES_256_GCM_SHA384"; "TLS_CHACHA20_POLY1305_SHA256" };
		};
		intermediate = {
			protocol = "tlsv1_2+";
			dhparam = ffdhe2048;
			options = { cipher_server_preference = false };
			ciphers = {
				"ECDHE-ECDSA-AES128-GCM-SHA256";
				"ECDHE-RSA-AES128-GCM-SHA256";
				"ECDHE-ECDSA-AES256-GCM-SHA384";
				"ECDHE-RSA-AES256-GCM-SHA384";
				"ECDHE-ECDSA-CHACHA20-POLY1305";
				"ECDHE-RSA-CHACHA20-POLY1305";
			};
			curveslist = { "X25519MLKEM768"; "X25519"; "prime256v1"; "secp384r1" };
			ciphersuites = { "TLS_AES_128_GCM_SHA256"; "TLS_AES_256_GCM_SHA384"; "TLS_CHACHA20_POLY1305_SHA256" };
		};
	};

	["5.8"] = {
		-- Version 5.8 as of 2026-04-08
		modern = {
			protocol = "tlsv1_3";
			options = { cipher_server_preference = false };
			ciphers = "DEFAULT"; -- TLS 1.3 uses 'ciphersuites' rather than these
			curveslist = { "X25519MLKEM768"; "X25519"; "prime256v1"; "secp384r1" };
			ciphersuites = { "TLS_AES_128_GCM_SHA256"; "TLS_AES_256_GCM_SHA384"; "TLS_CHACHA20_POLY1305_SHA256" };
		};
		intermediate = {
			protocol = "tlsv1_2+";
			dhparam = ffdhe2048;
			options = { cipher_server_preference = false };
			ciphers = {
				"ECDHE-ECDSA-AES128-GCM-SHA256";
				"ECDHE-RSA-AES128-GCM-SHA256";
				"ECDHE-ECDSA-AES256-GCM-SHA384";
				"ECDHE-RSA-AES256-GCM-SHA384";
				"ECDHE-ECDSA-CHACHA20-POLY1305";
				"ECDHE-RSA-CHACHA20-POLY1305";
			};
			curveslist = { "X25519MLKEM768"; "X25519"; "prime256v1"; "secp384r1" };
			ciphersuites = { "TLS_AES_128_GCM_SHA256"; "TLS_AES_256_GCM_SHA384"; "TLS_CHACHA20_POLY1305_SHA256" };
		};
		old = {
			protocol = "tlsv1+";
			dhparam = ffdhe2048;
			options = { cipher_server_preference = true };
			ciphers = {
				"ECDHE-ECDSA-AES128-GCM-SHA256";
				"ECDHE-RSA-AES128-GCM-SHA256";
				"ECDHE-ECDSA-AES256-GCM-SHA384";
				"ECDHE-RSA-AES256-GCM-SHA384";
				"ECDHE-ECDSA-CHACHA20-POLY1305";
				"ECDHE-RSA-CHACHA20-POLY1305";
				"ECDHE-ECDSA-AES128-SHA256";
				"ECDHE-RSA-AES128-SHA256";
				"ECDHE-ECDSA-AES128-SHA";
				"ECDHE-RSA-AES128-SHA";
				"ECDHE-ECDSA-AES256-SHA384";
				"ECDHE-RSA-AES256-SHA384";
				"ECDHE-ECDSA-AES256-SHA";
				"ECDHE-RSA-AES256-SHA";
				"AES128-GCM-SHA256";
				"AES256-GCM-SHA384";
				"AES128-SHA256";
				"AES256-SHA256";
				"AES128-SHA";
				"AES256-SHA";
				"DES-CBC3-SHA";
			};
			curveslist = { "X25519MLKEM768"; "X25519"; "prime256v1"; "secp384r1" };
			ciphersuites = { "TLS_AES_128_GCM_SHA256"; "TLS_AES_256_GCM_SHA384"; "TLS_CHACHA20_POLY1305_SHA256" };
		};
	};

	["5.7"] = {
		-- Version 5.7 as of 2023-07-09
		modern = {
			protocol = "tlsv1_3";
			options = { cipher_server_preference = false };
			ciphers = "DEFAULT"; -- TLS 1.3 uses 'ciphersuites' rather than these
			curveslist = { "X25519"; "prime256v1"; "secp384r1" };
			ciphersuites = { "TLS_AES_128_GCM_SHA256"; "TLS_AES_256_GCM_SHA384"; "TLS_CHACHA20_POLY1305_SHA256" };
		};
		intermediate = {
			protocol = "tlsv1_2+";
			dhparam = ffdhe2048;
			options = { cipher_server_preference = false };
			ciphers = {
				"ECDHE-ECDSA-AES128-GCM-SHA256";
				"ECDHE-RSA-AES128-GCM-SHA256";
				"ECDHE-ECDSA-AES256-GCM-SHA384";
				"ECDHE-RSA-AES256-GCM-SHA384";
				"ECDHE-ECDSA-CHACHA20-POLY1305";
				"ECDHE-RSA-CHACHA20-POLY1305";
				"DHE-RSA-AES128-GCM-SHA256";
				"DHE-RSA-AES256-GCM-SHA384";
				"DHE-RSA-CHACHA20-POLY1305";
			};
			curveslist = { "X25519"; "prime256v1"; "secp384r1" };
			ciphersuites = { "TLS_AES_128_GCM_SHA256"; "TLS_AES_256_GCM_SHA384"; "TLS_CHACHA20_POLY1305_SHA256" };
		};
		old = {
			protocol = "tlsv1+";
			dhparam = nil; -- openssl dhparam 1024
			options = { cipher_server_preference = true };
			ciphers = {
				"ECDHE-ECDSA-AES128-GCM-SHA256";
				"ECDHE-RSA-AES128-GCM-SHA256";
				"ECDHE-ECDSA-AES256-GCM-SHA384";
				"ECDHE-RSA-AES256-GCM-SHA384";
				"ECDHE-ECDSA-CHACHA20-POLY1305";
				"ECDHE-RSA-CHACHA20-POLY1305";
				"DHE-RSA-AES128-GCM-SHA256";
				"DHE-RSA-AES256-GCM-SHA384";
				"DHE-RSA-CHACHA20-POLY1305";
				"ECDHE-ECDSA-AES128-SHA256";
				"ECDHE-RSA-AES128-SHA256";
				"ECDHE-ECDSA-AES128-SHA";
				"ECDHE-RSA-AES128-SHA";
				"ECDHE-ECDSA-AES256-SHA384";
				"ECDHE-RSA-AES256-SHA384";
				"ECDHE-ECDSA-AES256-SHA";
				"ECDHE-RSA-AES256-SHA";
				"DHE-RSA-AES128-SHA256";
				"DHE-RSA-AES256-SHA256";
				"AES128-GCM-SHA256";
				"AES256-GCM-SHA384";
				"AES128-SHA256";
				"AES256-SHA256";
				"AES128-SHA";
				"AES256-SHA";
				"DES-CBC3-SHA";
			};
			curveslist = { "X25519"; "prime256v1"; "secp384r1" };
			ciphersuites = { "TLS_AES_128_GCM_SHA256"; "TLS_AES_256_GCM_SHA384"; "TLS_CHACHA20_POLY1305_SHA256" };
		};
	};
};

local function get_valid_versions()
	return array.collect(it.keys(profiles)):sort(version_compare):reverse();
end

local pref_order = { modern = 100, intermediate = 50, old = 0 };

local function sort_profile_by_pref(a, b)
	local pref_a, pref_b = pref_order[a] or 0, pref_order[b] or 0;
	return pref_a > pref_b; -- Best first
end

local function get_valid_profile_names(version)
	if version == "latest" then
		version = latest_version;
	end
	local version_profiles = profiles[version or default_version];
	if not version_profiles then
		return nil, "unknown-version";
	end
	return array.collect(it.keys(version_profiles)):sort(sort_profile_by_pref);
end

local function get_profile(version, profile_name)
	if version == "latest" then
		version = latest_version;
	end
	local version_profiles = profiles[version or default_version];
	if not version_profiles then
		return nil, "unknown-version";
	end
	local profile = version_profiles[profile_name or default_profile];
	if not profile then
		return nil, "unknown-profile";
	end
	return profile;
end

local function get_default_version()
	return default_version;
end

local function get_latest_version()
	return latest_version;
end

local function get_default_profile_name(version)
	-- Default profile name is currently the same across all versions,
	-- but can't guarantee this in the future - ensure valid version
	if version ~= "latest" and not profiles[version or default_version] then
		return nil, "unknown-version";
	end
	return default_profile;
end

return {
	profiles = profiles;
	get_default_version = get_default_version;
	get_latest_version = get_latest_version;
	get_default_profile_name = get_default_profile_name;
	get_valid_versions = get_valid_versions;
	get_valid_profile_names = get_valid_profile_names;
	get_profile = get_profile;
};
