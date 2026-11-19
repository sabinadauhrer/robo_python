#!/bin/sh
# Baut die Web-App und veröffentlicht sie auf GitHub Pages (Zweig gh-pages).
# Aufruf im Projektordner:  sh tool/deploy.sh
set -e
REPO_URL=$(git remote get-url origin)
NAME=$(basename -s .git "$REPO_URL")

flutter test
flutter build web --release --base-href "/$NAME/"

# Versionsnummer an die Dateien hängen, damit Browser (vor allem auf dem Handy)
# nach einem Update nicht die alte Version aus dem Zwischenspeicher nehmen.
V=$(date +%s)
perl -pi -e "s#\"mainJsPath\":\"main.dart.js\"#\"mainJsPath\":\"main.dart.js?v=$V\"#" build/web/flutter_bootstrap.js
perl -pi -e "s#flutter_bootstrap.js\"#flutter_bootstrap.js?v=$V\"#; s#sfx.js\"#sfx.js?v=$V\"#" build/web/index.html

TMP=$(mktemp -d)
cp -R build/web/. "$TMP"
touch "$TMP/.nojekyll"
cd "$TMP"
git init -q -b gh-pages
git add -A
git commit -q -m "Web-App veröffentlichen"
git push -q -f "$REPO_URL" gh-pages
rm -rf "$TMP"
echo "Fertig! In 1–2 Minuten online: https://$(echo "$REPO_URL" | sed -E 's#.*github.com[/:]([^/]+)/.*#\1#').github.io/$NAME/"
