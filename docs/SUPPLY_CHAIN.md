# Supply chain

## Pinning policy

- GitHub Actions are pinned to full commit SHAs with a version comment.
- Container base images are pinned to registry digests.
- Third-party source tarballs are pinned in deps.lock with a sha256
  verified at fetch time by scripts/fetch-deps.sh.
- Dependency versions are the newest stable release at least 7 days
  old at selection time.

## What a release contains

- prosodyx-<version>-source.tar.gz: reproducible source tarball made
  with git archive and gzip -n
- prosodyx-<version>-source.tar.gz.sha256
- prosodyx-<version>-sbom.cyclonedx.json and
  prosodyx-<version>-sbom.spdx.json: image SBOMs, and the CycloneDX file
  also carries the Lua source dependencies from deps.lock
- prosodyx-<version>.openvex.json: OpenVEX statements for the image
- *.sigstore.json: keyless cosign bundles for every asset
- Container image ghcr.io/quad4-software/prosodyx signed with cosign,
  with cosign attestations for both SBOMs and the OpenVEX document,
  plus GitHub attestations for source provenance, image provenance and
  the SPDX SBOM

## Verification

Replace <TAG> and <VERSION> (for example v13.0.7-quad4.2 and
13.0.7-quad4.2) and <DIGEST> with the image digest from the release.

Source tarball provenance:

```sh
gh attestation verify prosodyx-<VERSION>-source.tar.gz \
  --repo Quad4-Software/prosodyx
```

Image signature:

```sh
cosign verify ghcr.io/quad4-software/prosodyx@<DIGEST> \
  --certificate-identity-regexp \
  'https://github.com/Quad4-Software/prosodyx/.github/workflows/build.yml@refs/tags/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

Image attestations:

```sh
cosign verify-attestation --type cyclonedx \
  ghcr.io/quad4-software/prosodyx@<DIGEST> \
  --certificate-identity-regexp \
  'https://github.com/Quad4-Software/prosodyx/.github/workflows/build.yml@refs/tags/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

cosign verify-attestation --type spdxjson \
  ghcr.io/quad4-software/prosodyx@<DIGEST> \
  --certificate-identity-regexp \
  'https://github.com/Quad4-Software/prosodyx/.github/workflows/build.yml@refs/tags/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

cosign verify-attestation --type openvex \
  ghcr.io/quad4-software/prosodyx@<DIGEST> \
  --certificate-identity-regexp \
  'https://github.com/Quad4-Software/prosodyx/.github/workflows/build.yml@refs/tags/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

Release asset signatures:

```sh
cosign verify-blob --bundle <asset>.sigstore.json \
  --certificate-identity-regexp \
  'https://github.com/Quad4-Software/prosodyx/.github/workflows/release.yml@refs/tags/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  <asset>
```

Applying the VEX document during a vulnerability scan:

```sh
grype ghcr.io/quad4-software/prosodyx@<DIGEST> \
  --vex prosodyx-<VERSION>.openvex.json
```

Reproducing the source tarball from the tag:

```sh
git clone https://github.com/Quad4-Software/prosodyx
cd prosodyx
git checkout <TAG>
git archive --prefix=prosodyx-<VERSION>/ HEAD | gzip -n \
  > prosodyx-<VERSION>-source.tar.gz
sha256sum -c prosodyx-<VERSION>-source.tar.gz.sha256
```

## SLSA posture

Release artifacts are produced by a dedicated reusable workflow on
GitHub-hosted runners and signed through Sigstore keyless signing, so
provenance can be verified back to the tag and workflow. This meets
SLSA Build level 2. Build level 3 is not claimed: the builds are not
yet proven to run on isolated, hardened builders.
