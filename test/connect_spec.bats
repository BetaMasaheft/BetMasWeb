#!/usr/bin/env bats

# Basic start-up and connection smoke tests

@test "container can be reached via http" {
  result=$(curl -Is http://127.0.0.1:8080/ | grep -o 'Jetty')
  [ "$result" == 'Jetty' ]
}

@test "logs show clean start" {
  result=$(docker compose logs exist | grep -o 'Server has started')
  [ "$result" == 'Server has started' ]
}

@test "logs are error free" {
  result=$(docker compose logs exist | grep -ow -c 'ERROR' || true)
  [ "$result" -eq 0 ]
}
