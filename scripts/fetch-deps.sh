#!/bin/sh
# Download and verify the source tarballs listed in deps.lock.
# Usage: fetch-deps.sh <deps.lock> <output-dir>
# Creates <output-dir>/<name>-<version>/ source trees plus a
# <output-dir>/tarballs directory with the downloaded archives.

set -eu

lockfile=${1:?usage: fetch-deps.sh <deps.lock> <output-dir>}
outdir=${2:?usage: fetch-deps.sh <deps.lock> <output-dir>}

mkdir -p "$outdir/tarballs"

while IFS="$(printf '\t')" read -r name version url sha256 _license _purl; do
	case "$name" in
		''|\#*) continue ;;
	esac
	archive="$outdir/tarballs/$name-$version.tar.gz"
	curl --fail -L --proto '=https' --tlsv1.2 -sS -o "$archive" "$url"
	echo "$sha256  $archive" | sha256sum -c -
	tar -xzf "$archive" -C "$outdir"
	dir=$(tar -tzf "$archive" | head -1 | cut -d/ -f1)
	if [ "$dir" != "$name-$version" ]; then
		mv "$outdir/$dir" "$outdir/$name-$version"
	fi
done < "$lockfile"
