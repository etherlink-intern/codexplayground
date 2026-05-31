#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY="${ROOT_DIR}/.build/debug/swift-markitdown"

swift build --package-path "${ROOT_DIR}" --product swift-markitdown

run_case() {
  local name="$1"
  local input="${ROOT_DIR}/Tests/Fixtures/${name}"
  local expected="${ROOT_DIR}/Tests/Expected/${name%.*}.md"
  local actual
  actual="$(mktemp)"

  "${BINARY}" "${input}" > "${actual}"

  if ! diff -u "${expected}" "${actual}"; then
    echo "Smoke test failed for ${name}" >&2
    rm -f "${actual}"
    return 1
  fi

  rm -f "${actual}"
  echo "✓ ${name}"
}

run_case note.txt
run_case page.html
run_case table.csv
run_case data.json
