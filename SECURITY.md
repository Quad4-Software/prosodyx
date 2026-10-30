# Security policy

## Reporting a vulnerability

Report vulnerabilities through GitHub private vulnerability reporting
on this repository. Do not open public issues for security reports.

## Supported versions

Only the latest prosodyx release is supported. Fixes ship as a new
release rather than patches to older tags.

## Scope

In scope:

- the prosodyx source tree and its patches over upstream Prosody
- the hardened configuration shipped in prosody.cfg.lua.dist and
  docker/prosody.cfg.lua
- the container build, CI and release workflows in this repository
- the vendored dependencies listed in deps.lock

Out of scope:

- unmodified upstream Prosody code paths. Report those to the Prosody
  project per https://prosody.im/security and they will be picked up by
  the next upstream rebase
- deployments that changed the shipped configuration

## Process

Reports are acknowledged as they are read. Confirmed issues are fixed
in private, released, and then disclosed in the release notes. We ask
reporters to follow coordinated disclosure and give us reasonable time
to ship a fix before publishing details.
