#!/usr/bin/env bash
set -euo pipefail

image_dir="bin/targets/x86/64"
manifest="$(find "$image_dir" -maxdepth 1 -type f -name '*generic.manifest' -print -quit)"

[[ -n "$manifest" && -s "$manifest" ]] || {
	echo "Missing x86_64 generic package manifest" >&2
	exit 1
}

for package in kmod-tun kmod-nf-conntrack-netlink; do
	if ! awk -v package="$package" '$1 == package { found = 1 } END { exit !found }' "$manifest"; then
		echo "Required OpenClash kernel module is missing from the x86_64 firmware manifest: $package" >&2
		exit 1
	fi
done

echo "Verified OpenClash kernel modules in $manifest"
