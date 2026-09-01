#!/usr/bin/env bats

# Basic start-up and connection smoke tests
# Adapted from https://github.com/eeditiones/jinks/blob/main/test/01-smoke.bats

@test "container jvm responds from client" {
  run docker exec exist java -version
  [ "$status" -eq 0 ]
}

@test "container can be reached via http" {
  result=$(curl -Is http://127.0.0.1:8080/ | grep -o 'Jetty')
  [ "$result" == 'Jetty' ]
}

@test "container reports healthy to docker" {
  result=$(docker ps | grep -c '(healthy)')
  [ "$result" -eq 1 ]
}

@test "logs show clean start" {
  result=$(docker logs exist | grep -o 'Server has started')
  [ "$result" == 'Server has started' ]
}

# Packages install at image build via docker/overlay-packages.xq (repo:*), not
# at container boot. Verify deployed versions directly instead of inferring
# from runtime autodeploy logs (exist-db/exist#5579 skip is invisible there).
@test "BetMasService overlay deployed" {
  result=$(docker exec exist java org.exist.start.Main client --no-gui -l -u admin -P "" --xpath 'string(doc("/db/apps/BetMasService/expath-pkg.xml")/*:package/@version)')
  [ "$result" = "0.1" ]
}

@test "parser overlay deployed" {
  result=$(docker exec exist java org.exist.start.Main client --no-gui -l -u admin -P "" --xpath 'string(doc("/db/apps/parser/expath-pkg.xml")/*:package/@version)')
  [ "$result" = "0.5" ]
}

@test "BetMasWeb overlay deployed this build" {
  result=$(docker exec exist java org.exist.start.Main client --no-gui -l -u admin -P "" --xpath 'string(doc("/db/apps/BetMasWeb/expath-pkg.xml")/*:package/@version)')
  [ "$result" = "0.2.0" ]
}

@test "BetMasWeb overlay content canary present" {
  result=$(docker exec exist java org.exist.start.Main client --no-gui -l -u admin -P "" --xpath 'contains(util:binary-to-string(util:binary-doc("/db/apps/BetMasWeb/modules/queries.xqm")), "q:ms-parts-count-filter")')
  [ "$result" = "true" ]
}

@test "logs are error free" {
  result=$(docker logs exist | grep -ow -c 'ERROR' || true)
  [ "$result" -eq 0 ]
}

@test "no fatalities in logs" {
  result=$(docker logs exist | grep -ow -c 'FATAL' || true)
  [ "$result" -eq 0 ]
}

# Check for cgroup config warning
@test "check logs for cgroup file warning" {
  result=$(docker logs exist | grep -ow -c 'Unable to open cgroup memory limit file' || true)
  [ "$result" -eq 0 ]
}
