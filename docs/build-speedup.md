# Build acceleration notes

The x86_64 and NanoPi R2S workflows keep the normal Q-WRT source build as the authoritative path. They speed up repeat runs with three isolated caches: downloaded source archives, ccache objects, and a target-specific prebuilt OpenWrt toolchain.

The toolchain cache uses an exact key derived from the resolved `.config`, toolchain and build include files, shared build rules, target kernel tree, and scripts. A cache hit reuses the matching toolchain. On a miss, `make toolchain/install` builds it from this checkout and the regular full firmware build continues. Cache eviction or an unavailable cache therefore affects speed only.

The ccache key is target-specific and tied to the resolved configuration; its restore prefix allows safe compiler-cache reuse across nearby configurations because ccache validates compiler and command inputs. Download caches are also separate per target. OpenWrt's download step remains enabled and validates/fetches whatever the current source tree requires.

## ImageBuilder compatibility

No ImageBuilder mode is enabled. The referenced 25.12 ImageBuilder workflows use ImmortalWrt prebuilt images, not a verified Q-WRT build artifact. They do not establish that Q-WRT's selected package set, patches, feeds, kernel, and device image recipes can be reproduced from those images. The Rockchip reference also documents a third-party package limitation. Keep full source builds until a Q-WRT-matched ImageBuilder is produced and its x86 and R2S outputs are verified against the source-build images.
