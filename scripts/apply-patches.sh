#!/bin/bash
#
# Given a series.conf file and a directory with patches, applies them to the
# current directory.
# Used by kernel-source.spec.in and kernel-binary.spec.in

USAGE="$0 [--vanilla] <series.conf> <patchdir> [symbol ...]"

set -e
set -o pipefail
vanilla=false
if test "$1" == "--vanilla"; then
	vanilla=true
	shift
fi
if test $# -lt 2; then
	echo "$USAGE" >&2
	exit 1
fi
DIR="${0%/*}"
SERIES_CONF=$1
PATCH_DIR=$2
shift 2

trap 'rm -f "$series"' EXIT
series=$(mktemp)
# support for patches in patches.addon/series
cp "$SERIES_CONF" "$series"

(
	echo "trap 'echo \"*** patch \$_ failed ***\"' ERR"
	echo "set -ex"
	"$DIR"/guard.py "$@" <"$series" | \
	if $vanilla; then
		egrep '^patches\.(kernel\.org|rpmify)/'
	else
		cat
	fi |\
	sed "s|^|patch -s -F1 -p1 --no-backup-if-mismatch -i $PATCH_DIR/|"
) | sh

