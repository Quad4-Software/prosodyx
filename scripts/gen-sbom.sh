#!/usr/bin/env bash
# Generate a CycloneDX 1.6 SBOM for prosodyx from deps.lock and
# prosody.release, or merge the source dependencies into an existing
# CycloneDX document.
#
# Usage:
#   gen-sbom.sh                  write a new SBOM to stdout
#   gen-sbom.sh --merge <file>   append deps.lock entries to <file>

set -euo pipefail

cd "$(dirname "$0")/.."
exec python3 - "$@" <<'PYEOF'
import json
import sys
import uuid

def read_version():
    with open("prosody.release", encoding="ascii") as fh:
        return fh.read().strip()

def read_deps():
    deps = []
    with open("deps.lock", encoding="ascii") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            name, version, url, sha256, license_id, purl = line.split("\t")
            deps.append({
                "type": "library",
                "bom-ref": purl,
                "name": name,
                "version": version,
                "purl": purl,
                "licenses": [{"license": {"id": license_id}}],
                "hashes": [{"alg": "SHA-256", "content": sha256}],
                "externalReferences": [{"type": "distribution", "url": url}],
            })
    return deps

def root_component(version):
    return {
        "type": "application",
        "bom-ref": f"pkg:github/Quad4-Software/prosodyx@{version}",
        "name": "prosodyx",
        "version": version,
        "purl": f"pkg:github/Quad4-Software/prosodyx@{version}",
        "licenses": [{"license": {"id": "MIT"}}],
        "supplier": {"name": "Quad4 Software"},
    }

def new_bom(version):
    root = root_component(version)
    return {
        "bomFormat": "CycloneDX",
        "specVersion": "1.6",
        "serialNumber": f"urn:uuid:{uuid.uuid5(uuid.NAMESPACE_URL, 'https://github.com/Quad4-Software/prosodyx@' + version)}",
        "version": 1,
        "metadata": {
            "component": root,
        },
        "components": [root] + read_deps(),
        "dependencies": [
            {"ref": root["bom-ref"], "dependsOn": [d["purl"] for d in read_deps()]},
        ],
    }

def merge(path, version):
    with open(path, encoding="utf-8") as fh:
        bom = json.load(fh)
    root = root_component(version)
    deps = read_deps()
    have = {c.get("purl") for c in bom.get("components", [])}
    new = [c for c in [root] + deps if c["purl"] not in have]
    bom.setdefault("components", []).extend(new)
    dep_list = bom.setdefault("dependencies", [])
    refs = {d["ref"] for d in dep_list}
    if root["bom-ref"] not in refs:
        dep_list.append({"ref": root["bom-ref"], "dependsOn": [d["purl"] for d in deps]})
    return bom

if len(sys.argv) >= 3 and sys.argv[1] == "--merge":
    out = merge(sys.argv[2], read_version())
elif len(sys.argv) == 1:
    out = new_bom(read_version())
else:
    sys.stderr.write("usage: gen-sbom.sh [--merge <cyclonedx.json>]\n")
    sys.exit(2)

json.dump(out, sys.stdout, indent=2, sort_keys=True)
sys.stdout.write("\n")
PYEOF
