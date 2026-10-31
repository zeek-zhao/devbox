#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L2-003-executable-jar"
rm -rf "$OUT"
mkdir -p "$OUT/classes"
javac --release 21 -d "$OUT/classes" src/app/Main.java src/app/Message.java
jar --create --file "$OUT/app.jar" --main-class app.Main -C "$OUT/classes" .
jar --list --file "$OUT/app.jar" > "$OUT/contents.txt"
grep -Fxq 'app/Main.class' "$OUT/contents.txt"
grep -Fxq 'app/Message.class' "$OUT/contents.txt"
echo "jar-contents=entry-and-helper"
java -jar "$OUT/app.jar"
