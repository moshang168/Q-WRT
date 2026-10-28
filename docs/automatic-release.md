# Automatic firmware releases

Pushes to `upgrade-openwrt-25.12` build x86_64 and NanoPi R2S firmware independently. Once both builds for the same source commit succeed, the release helper packages each target output directory as a `.tar.gz` bundle, generates a `SHA256SUMS` file for the bundles, and publishes one GitHub Release tagged `q-wrt-<full-commit-sha>`.

If either target build fails, no release is published. Manual `workflow_dispatch` runs continue to build and upload the normal 14-day Actions artifacts; they do not publish a release. A repeated run for a commit with an existing published release is a no-op, so it does not replace published assets.

The helper waits for the other device's build job for the same branch and commit, then downloads both artifacts. Its job has `actions: read` to fetch workflow artifacts and `contents: write` to create the release. Both firmware bundles include the full target output directory (firmware images and build metadata); the release also contains checksums for the downloaded bundles.
