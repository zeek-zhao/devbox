#!/usr/bin/env bats

@test "run captures successful output and status" {
  run bash demo.sh report
  [ "$status" -eq 0 ]
  [ "$output" = "result=ready" ]
}

@test "run captures rejected output and status" {
  run bash demo.sh reject
  [ "$status" -eq 7 ]
  [ "$output" = "result=denied" ]
}
