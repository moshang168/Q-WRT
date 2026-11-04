#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y --no-install-recommends qemu-system-x86

image="$(find bin/targets/x86/64 -maxdepth 1 -type f -name '*generic-ext4-combined.img.gz' -print -quit)"
[[ -n "$image" && -s "$image" ]] || {
	echo "Missing x86_64 generic ext4 combined disk image" >&2
	exit 1
}

disk="$(mktemp --suffix=.img)"
serial_log="$(mktemp)"
qemu_log="$(mktemp)"
qemu_pid=""
cleanup() {
	if [[ -n "$qemu_pid" ]]; then
		kill "$qemu_pid" 2>/dev/null || true
		wait "$qemu_pid" 2>/dev/null || true
	fi
	rm -f "$disk" "$serial_log" "$qemu_log"
}
trap cleanup EXIT

gzip -dc "$image" > "$disk"
qemu-system-x86_64 \
	-accel tcg \
	-machine pc \
	-m 512 \
	-display none \
	-serial "file:$serial_log" \
	-monitor none \
	-no-reboot \
	-drive "file=$disk,format=raw,if=ide" \
	-netdev user,id=net0 \
	-device e1000,netdev=net0 \
	> "$qemu_log" 2>&1 &
qemu_pid=$!

booted=0
for _ in $(seq 1 120); do
	if grep -q 'Please press Enter to activate this console\.' "$serial_log" 2>/dev/null; then
		booted=1
		break
	fi
	if ! kill -0 "$qemu_pid" 2>/dev/null; then
		break
	fi
	sleep 1
done

if (( ! booted )); then
	echo "x86 firmware did not reach the OpenWrt console in QEMU" >&2
	cat "$serial_log" >&2 || true
	cat "$qemu_log" >&2 || true
	exit 1
fi

grep -q 'kmodloader: done loading kernel modules from /etc/modules.d/' "$serial_log" || {
	echo "x86 firmware did not finish loading its kernel modules in QEMU" >&2
	cat "$serial_log" >&2
	exit 1
}
grep -q 'tun: Universal TUN/TAP device driver' "$serial_log" || {
	echo "kmod-tun did not load in the x86 QEMU guest" >&2
	cat "$serial_log" >&2
	exit 1
}

echo "Verified x86 firmware booted through OpenWrt init in QEMU"
tail -n 40 "$serial_log"
