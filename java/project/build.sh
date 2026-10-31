#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
mkdir -p build/classes build/include build/native build/empty
find build/classes -type f -name '*.class' -delete
mapfile -t SOURCES < <(find src -name '*.java' | sort)
javac --release 21 -encoding UTF-8 -Xlint:all -Werror -h build/include -d build/classes "${SOURCES[@]}" # L2-002-compile-bytecode
jar --create --file build/app.jar --main-class=Main -C build/classes . # L2-003-executable-jar
JDK="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"
cc -std=c11 -Wall -Wextra -Werror -shared -fPIC \
  -I"$JDK/include" -I"$JDK/include/linux" -Ibuild/include \
  -o build/native/libsnapshot.so src/devbox/tests/snapshot.c
javap -verbose -classpath build/classes Main >build/bytecode.txt
grep -q 'major version: 65' build/bytecode.txt
javadoc -quiet -Werror -Xdoclint:all -d build/docs -sourcepath src devbox.rest >build/javadoc.txt 2>&1
java -ea -cp build/classes SelfTest
java -ea -Djava.library.path=build/native -cp build/classes EngineeringTest
if java -ea -cp build/classes SelfTest --inject-failure >build/injected.txt 2>&1; then
  echo '[fail] injected assertion was accepted' >&2
  exit 1
fi
grep -q 'injected harness failure' build/injected.txt
if java -cp build/classes SelfTest >build/no-assertions.txt 2>&1; then
  echo '[fail] disabled assertions were accepted' >&2
  exit 1
fi
grep -q 'SelfTest requires -ea' build/no-assertions.txt
jshell --feedback concise --class-path build/classes src/probes.jsh >build/jshell.txt 2>&1
if grep -Eq 'Error:|Exception|错误:|异常' build/jshell.txt; then
  cat build/jshell.txt >&2
  exit 1
fi
grep -qx 'repl: ok' build/jshell.txt
java -jar build/app.jar --self-check
echo '[pass] java build OK'
