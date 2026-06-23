@echo off
REM build.bat — 构建前自动同步 CHANGELOG.md 到 assets/changelog.md
copy /Y "CHANGELOG.md" "assets\changelog.md" >nul
echo [build] assets/changelog.md synced.
flutter %*
