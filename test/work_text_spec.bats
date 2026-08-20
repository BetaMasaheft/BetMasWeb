#!/usr/bin/env bats

# Fast regression guards for Roaster document unwrap / work-text 500.
# Requires a running stack (default http://localhost:8080).
#
#   npm run test:regress

BASE_URL="${BETMAS_BASE_URL:-http://localhost:8080}"

@test "GET /works/LIT1709Kebran/text returns 200 (not Roaster-map XPath 500)" {
  code=$(curl -so /dev/null -w '%{http_code}' --max-time 90 "$BASE_URL/works/LIT1709Kebran/text")
  [ "$code" -eq 200 ]
}

@test "work-text body is HTML, not an XPTY0004 JSON error" {
  body=$(curl -sf --max-time 90 "$BASE_URL/works/LIT1709Kebran/text" | head -c 200)
  echo "$body" | grep -qi '<!DOCTYPE html\|<html'
  ! echo "$body" | grep -q 'XPTY0004'
}
