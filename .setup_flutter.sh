#!/bin/bash
set -e
rm -rf /tmp/flutter /tmp/flutter.tar.xz
cd /tmp
curl -sSL --retry 3 -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
echo "downloaded: $(ls -la flutter.tar.xz)"
tar xf flutter.tar.xz
git config --global --add safe.directory /tmp/flutter || true
/tmp/flutter/bin/flutter --version
echo FLUTTER_READY
