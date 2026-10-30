# prosodyx

prosodyx is a hardened fork of the Prosody XMPP server, based on
upstream Prosody 13.0.7. It is built and maintained by Quad4 Software.

## Differences from upstream

- Insecure and development-only modules removed.
- Hardened default configuration: TLS required on c2s and s2s,
  in-band registration disabled, PLAIN and DIGEST-MD5 SASL mechanisms
  disabled, tighter stanza size and timeout limits, console logging.
- Rootless, no-shell container image built on Chainguard bases.
- Reproducible source tarball, signed container images, SBOM and
  OpenVEX documents attached to every release.

See docs/HARDENING.md for the full list of changes.

## Quick start

Set the XMPP domain and provide TLS certificates:

```sh
export PROSODYX_DOMAIN=example.com
mkdir -p certs data
# place example.com.crt and example.com.key in certs/
podman run -d --name prosodyx \
  --cap-drop=all --security-opt=no-new-privileges --read-only \
  -e PROSODYX_DOMAIN \
  -v "$PWD/certs:/etc/prosody/certs:ro,Z" \
  -v prosodyx-data:/var/lib/prosody:Z \
  -p 5222:5222 -p 5269:5269 \
  ghcr.io/quad4-software/prosodyx:latest
```

Or use compose.yaml for a rootless deployment:

```sh
PROSODYX_DOMAIN=example.com podman compose up -d
```

Create an account:

```sh
podman exec -it prosodyx /usr/bin/prosodyctl adduser user@example.com
```

## Verifying releases

Release tarballs, container images, SBOMs and VEX documents are signed
with Sigstore. See docs/SUPPLY_CHAIN.md for the exact commands.

## Upstream

prosodyx tracks hg.prosody.im. The base release is verified against the
signed upstream tarball. See docs/UPSTREAM.md for the merge procedure.

## License

MIT, same as upstream Prosody. See COPYING.
