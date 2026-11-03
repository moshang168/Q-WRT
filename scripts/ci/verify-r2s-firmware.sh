#!/usr/bin/env bash
set -euo pipefail

image_dir="bin/targets/rockchip/armv8"
image="$(find "$image_dir" -maxdepth 1 -type f -name '*friendlyarm_nanopi-r2s*sysupgrade.img.gz' -print -quit)"
manifest="$(find "$image_dir" -maxdepth 1 -type f -name '*friendlyarm_nanopi-r2s.manifest' -print -quit)"

[[ -n "$image" && -s "$image" ]] || { echo "Missing non-empty NanoPi R2S sysupgrade image" >&2; exit 1; }
[[ -n "$manifest" && -s "$manifest" ]] || { echo "Missing NanoPi R2S package manifest" >&2; exit 1; }

for package in dropbear dnsmasq firewall4 kmod-usb-net-rtl8152 luci luci-ssl luci-i18n-base-zh-cn; do
  if ! awk -v package="$package" '$1 == package { found = 1 } END { exit !found }' "$manifest"; then
    echo "Required package is missing from the R2S firmware manifest: $package" >&2
    exit 1
  fi
done

grep -q 'VERSION_NUMBER:.*25\.12\.6' include/version.mk || {
  echo "Source tree is not based on OpenWrt 25.12.6" >&2
  exit 1
}

grep -q "192.168.2.1" files/etc/uci-defaults/99-q-wrt-nanopi-r2s || {
  echo "Fixed R2S LAN management address is missing from first-boot defaults" >&2
  exit 1
}

raw_image="$(mktemp)"
image_without_metadata="$(mktemp --suffix=.img.gz)"
partition_table="$(mktemp)"
trap 'rm -f "$raw_image" "$image_without_metadata" "$partition_table"' EXIT
cp "$image" "$image_without_metadata"
fwtool="staging_dir/host/bin/fwtool"
[[ -x "$fwtool" ]] || { echo "Missing host fwtool needed to validate OpenWrt image metadata" >&2; exit 1; }
"$fwtool" -s /dev/null -t "$image_without_metadata" || true
"$fwtool" -i /dev/null -t "$image_without_metadata"
gzip -t "$image_without_metadata"
gzip -dc "$image_without_metadata" > "$raw_image"
sfdisk --dump "$raw_image" > "$partition_table"
partition_count="$(grep -cE '^[^#].*:[[:space:]]+start=' "$partition_table" || true)"
if (( partition_count < 2 )); then
  echo "R2S image does not contain the expected boot and root filesystem partitions" >&2
  cat "$partition_table" >&2
  exit 1
fi

echo "Verified $image"
echo "Verified required LuCI, SSH, DHCP, firewall, and USB Ethernet packages"
echo "Verified compressed disk image and $partition_count partition entries"
