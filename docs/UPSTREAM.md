# Tracking upstream

## Base

prosodyx is based on Prosody 13.0.7 from https://hg.prosody.im. The
base release was verified against the signed release tarball:

- file: prosody-13.0.7.tar.gz
- sha256: f671df3c7535c7269afc89579ea26fc13d1006b40ef5df4ccb71a560197f151b
- signature: prosody-13.0.7.tar.gz.asc
- key: Matthew Wild <me@matthewwild.co.uk>
- fingerprint: 32A9EDDE3609931EB98CEAC315907E8E7BDD6BFE

The git history was imported from the Mercurial repository with hg-git.
Tags match upstream release tags, including 13.0.7.

## Upstream branches

Full upstream history is kept on local branches:

- upstream/trunk: the hg default branch
- upstream/13.0: the 13.0 stable line
- upstream/0.12: the 0.12 stable line

These exist for reference and merging only. They are not pushed.

## Releasing onto a new upstream version

The upstream-check workflow opens an issue when a new 13.x release
appears on https://prosody.im/downloads/source/. To move the fork to a
new upstream release:

1. Download the new release tarball and .asc from prosody.im and verify
   the signature with the release signing key above.
2. Import the new upstream history into the matching upstream/<branch>
   branch using hg-git against hg.prosody.im.
3. Rebase or merge the prosodyx commits onto the new upstream tag on a
   topic branch. Review upstream changes for conflicts with
   docs/HARDENING.md.
4. Update prosody.release to <version>-quad4.1 and reset any
   release-specific values.
5. Diff the extracted release tarball against the new git tag, as done
   for 13.0.7, and confirm only the expected generated files differ.
6. Run the test suite and the container smoke test, then tag
   v<version>-quad4.1 as an annotated tag on master.
