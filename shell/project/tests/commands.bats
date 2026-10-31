#!/usr/bin/env bats

# L2-004-bats-fixtures
setup() {
  bats_require_minimum_version 1.10.0
  ROOT="$(cd -- "$BATS_TEST_DIRNAME/.." && pwd)"
  MAIN="$ROOT/src/main.sh"
  fixture="$(mktemp -d)"
  export TMPDIR="$fixture"
  target="$fixture/target with spaces"
}

teardown() {
  rm -rf -- "$fixture"
}

deploy_fixture() {
  run bash "$MAIN" deploy --target "$target"
  [ "$status" -eq 0 ]
}

@test "fixed self-check, independent of current directory" {
  cd /
  # L2-003-bats-run-assertions
  run --separate-stderr bash "$MAIN" --self-check
  [ "$status" -eq 0 ]
  [ "$output" = $'deploy\tcreated\ndeploy\tunchanged\nCHECK        STATUS\nfiles        PASS\nintegrity    PASS\nlayout       PASS\nTOTAL 3 PASS 3 FAIL 0\nchecks=3\nself-check OK' ]
  [ -n "$stderr" ]
  [ -z "$(find "$fixture" -mindepth 1 -print)" ]
}

@test "deploy is idempotent and preserves the release inode" {
  deploy_fixture
  inode="$(stat -c %i "$target/release/service.txt")"
  run --separate-stderr bash "$MAIN" deploy --target "$target"
  [ "$status" -eq 0 ]
  [ "$output" = $'deploy\tunchanged' ]
  [ "$(stat -c %i "$target/release/service.txt")" = "$inode" ]
  [ -z "$(find "$target" -name '.stage.*' -print)" ]
}

@test "name validation and actual replacement / uppercase config" {
  run bash "$MAIN" deploy --target "$target" --name web-app
  [ "$status" -eq 0 ]
  [ "$(cat "$target/release/service.txt")" = $'service=web-app\nkey=WEB_APP\nstate=READY' ]
  run bash "$MAIN" deploy --target "$target" --name '-invalid'
  [ "$status" -eq 2 ]
  run bash "$MAIN" deploy --target "$target" --name abcdefghijklmnopqrstuvwxyzABCDEFG
  [ "$status" -eq 2 ]
}

@test "deploy refuses drift and leaves content untouched" {
  deploy_fixture
  printf 'corrupt\n' >"$target/release/service.txt"
  run bash "$MAIN" deploy --target "$target"
  [ "$status" -eq 2 ]
  [[ "$output" == *'invalid integrity'* ]]
  [ "$(cat "$target/release/service.txt")" = corrupt ]
}

@test "flock conflict is bounded and does not publish" {
  mkdir -p "$target"
  exec 8>"$target/.deploy.lock"
  flock 8
  run timeout 5 bash "$MAIN" deploy --target "$target"
  [ "$status" -eq 2 ]
  [[ "$output" == *'deployment is locked'* ]]
  [ ! -e "$target/release" ]
  exec 8>&-
}

@test "inspect runs all checks and emits sorted TSV on stdout only" {
  deploy_fixture
  run --separate-stderr bash "$MAIN" inspect --target "$target"
  [ "$status" -eq 0 ]
  [ "$output" = $'files\tPASS\nintegrity\tPASS\nlayout\tPASS' ]
  [[ "$stderr" == *'checks: files,integrity,layout'* ]]
}

@test "inspect corruption reports failures and still waits for all checks" {
  deploy_fixture
  printf 'corrupt\n' >"$target/release/service.txt"
  run --separate-stderr bash "$MAIN" inspect --target "$target"
  [ "$status" -eq 1 ]
  [ "$output" = $'files\tPASS\nintegrity\tFAIL\nlayout\tPASS' ]
}

@test "null-delimited paths and recursive layout include unusual filenames" {
  deploy_fixture
  mkdir -p "$target/release/nested/deep"
  printf 'extra\n' >"$target/release/nested/deep/"$'two\nlines.txt'
  run --separate-stderr bash "$MAIN" inspect --target "$target"
  [ "$status" -eq 1 ]
  [ "$output" = $'files\tFAIL\nintegrity\tPASS\nlayout\tFAIL' ]
}

@test "inspect rejects symlinks and unsafe manifests" {
  deploy_fixture
  ln -s service.txt "$target/release/alias"
  run --separate-stderr bash "$MAIN" inspect --target "$target"
  [ "$status" -eq 1 ]
  [[ "$output" == *$'files\tFAIL'* ]]
  printf '%064d  /etc/passwd\n' 0 >"$target/release/SHA256SUMS"
  run --separate-stderr bash "$MAIN" inspect --target "$target"
  [ "$status" -eq 1 ]
  [[ "$output" == *$'integrity\tFAIL'* ]]
}

@test "JSON policy uses nested enabled service selection" {
  deploy_fixture
  printf '{"policy":{"services":[{"name":"demo","enabled":true}]}}\n' >"$fixture/policy.json"
  run --separate-stderr bash "$MAIN" inspect --target "$target" --config "$fixture/policy.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'policy\tPASS' ]]
  printf '{"policy":{"services":[{"name":"demo","enabled":false}]}}\n' >"$fixture/policy.json"
  run --separate-stderr bash "$MAIN" inspect --target "$target" --config "$fixture/policy.json"
  [ "$status" -eq 1 ]
  [[ "$output" == *$'policy\tFAIL' ]]
  printf 'not JSON\n' >"$fixture/policy.json"
  run --separate-stderr bash "$MAIN" inspect --target "$target" --config "$fixture/policy.json"
  [ "$status" -eq 1 ]
  [[ "$stderr" == *'parse error'* ]]
}

@test "report sorts, counts FAIL and accepts unterminated final line" {
  printf 'zeta\tFAIL\nalpha\tPASS' >"$fixture/input"
  run bash "$MAIN" report --input "$fixture/input"
  [ "$status" -eq 0 ]
  [ "$output" = $'CHECK        STATUS\nalpha        PASS\nzeta         FAIL\nTOTAL 2 PASS 1 FAIL 1' ]
  run bash "$MAIN" report -f "$fixture/input"
  [ "$status" -eq 0 ]
  [[ "$output" == *'TOTAL 2 PASS 1 FAIL 1' ]]
}

@test "report rejects invalid, duplicate and empty rows" {
  for text in '' $'a\tMAYBE\n' $'a\tPASS\na\tFAIL\n' $'a\tPASS\textra\n' $'a\tPASS\t\n' $'\tPASS\n'; do
    printf '%s' "$text" >"$fixture/input"
    run bash "$MAIN" report --input "$fixture/input"
    [ "$status" -eq 2 ]
    [[ "$output" == *'[error]'* ]]
  done
}

@test "CLI rejects missing, duplicate, irrelevant and unknown options" {
  for command in deploy inspect report; do
    run bash "$MAIN" "$command"
    [ "$status" -eq 2 ]
    run bash "$MAIN" "$command" --unknown
    [ "$status" -eq 2 ]
  done
  run bash "$MAIN" deploy --target
  [ "$status" -eq 2 ]
  run bash "$MAIN" deploy --target "$target" --name demo --name demo
  [ "$status" -eq 2 ]
  run bash "$MAIN" inspect --target "$target" --name demo
  [ "$status" -eq 2 ]
  run bash "$MAIN" report -f
  [ "$status" -eq 2 ]
  run bash "$MAIN" report -x
  [ "$status" -eq 2 ]
  run bash "$MAIN" report -h -x
  [ "$status" -eq 2 ]
  run bash "$MAIN" report -h extra
  [ "$status" -eq 2 ]
  run bash "$MAIN" --self-check extra
  [ "$status" -eq 2 ]
  run bash "$MAIN" --help
  [ "$status" -eq 0 ]
}

@test "TERM cleans staging with FIFO handshake, no sleep synchronization" {
  mkdir -p "$fixture/bin"
  mkfifo "$fixture/ready" "$fixture/release"
  cat >"$fixture/bin/sha256sum" <<'WRAPPER'
#!/usr/bin/env bash
printf 'ready\n' >"$READY"
read -r answer <"$RELEASE"
exec /usr/bin/sha256sum "$@"
WRAPPER
  chmod +x "$fixture/bin/sha256sum"
  # timeout bounds both the handshake and the command being signalled.
  run --separate-stderr timeout 10 bash -c '
    export READY="$1/ready" RELEASE="$1/release" PATH="$1/bin:$PATH"
    bash "$2" deploy --target "$1/target" &
    pid=$!
    read -r ready <"$READY"
    kill -TERM "$pid"
    printf "continue\n" >"$RELEASE"
    if wait "$pid"; then exit 99; else rc=$?; fi
    [[ $rc -eq 143 ]] || exit "$rc"
    [[ -z "$(find "$1/target" -name ".stage.*" -print)" ]]
    [[ ! -e "$1/target/release" ]]
  ' bash "$fixture" "$MAIN"
  [ "$status" -eq 0 ]
}

@test "INT and TERM reap blocked inspection workers and clean temporary files" {
  deploy_fixture
  mkdir -p "$fixture/bin"
  cat >"$fixture/bin/sha256sum" <<'WRAPPER'
#!/usr/bin/env bash
printf '%s\n' "$$" >"$READY"
read -r answer <"$RELEASE"
exec /usr/bin/sha256sum "$@"
WRAPPER
  chmod +x "$fixture/bin/sha256sum"
  for signal in INT TERM; do
    mkfifo "$fixture/ready-$signal" "$fixture/release-$signal"
    mkdir "$fixture/tmp-$signal"
    run --separate-stderr timeout 10 bash -c '
      set -m
      export READY="$1/ready-$3" RELEASE="$1/release-$3" PATH="$1/bin:$PATH" TMPDIR="$1/tmp-$3"
      bash "$2" inspect --target "$1/target with spaces" &
      pid=$!
      read -r worker <"$READY"
      kill -"$3" "$pid"
      if wait "$pid"; then exit 99; else rc=$?; fi
      case "$3:$rc" in INT:130|TERM:143) ;; *) exit 98 ;; esac
      if kill -0 "$worker"; then exit 97; fi
      [[ -z "$(find "$TMPDIR" -mindepth 1 -print)" ]]
    ' bash "$fixture" "$MAIN" "$signal"
    [ "$status" -eq 0 ]
  done
}
