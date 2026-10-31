#!/usr/bin/env bats

setup() {
  FIXTURE="$FIXTURE_ROOT/test-$BATS_TEST_NUMBER"
  mkdir "$FIXTURE"
  printf 'seed\n' >"$FIXTURE/state"
}

teardown() {
  rm -rf "$FIXTURE"
}

@test "fixture changes stay within this test" {
  printf 'changed\n' >"$FIXTURE/state"
  [ "$(cat "$FIXTURE/state")" = "changed" ]
}

@test "the next test receives a fresh fixture" {
  [ "$(cat "$FIXTURE/state")" = "seed" ]
}
