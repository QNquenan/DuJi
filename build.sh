#!/usr/bin/env bash
# build.sh — 构建前自动同步 CHANGELOG.md 到 assets/changelog.md
cp CHANGELOG.md assets/changelog.md
echo "[build] assets/changelog.md synced."
flutter "$@"
