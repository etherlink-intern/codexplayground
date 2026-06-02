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

run_error_case() {
  local name="$1"
  local expected_message="$2"
  local input="${ROOT_DIR}/Tests/Fixtures/${name}"
  local stdout_file
  local stderr_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"

  if "${BINARY}" "${input}" > "${stdout_file}" 2> "${stderr_file}"; then
    echo "Smoke test unexpectedly succeeded for ${name}" >&2
    rm -f "${stdout_file}" "${stderr_file}"
    return 1
  fi

  if [[ -s "${stdout_file}" ]]; then
    echo "Smoke test expected no stdout for ${name}" >&2
    cat "${stdout_file}" >&2
    rm -f "${stdout_file}" "${stderr_file}"
    return 1
  fi

  if ! grep -Fq "${expected_message}" "${stderr_file}"; then
    echo "Smoke test did not surface expected error for ${name}" >&2
    echo "Expected to find: ${expected_message}" >&2
    echo "Actual stderr:" >&2
    cat "${stderr_file}" >&2
    rm -f "${stdout_file}" "${stderr_file}"
    return 1
  fi

  rm -f "${stdout_file}" "${stderr_file}"
  echo "✓ ${name} error"
}

run_case note.txt
run_case page.html
run_case table.csv
run_case data.json
run_case empty.txt
run_case empty.md
run_case empty.html
run_case empty.csv

run_error_case empty.json "swift-markitdown: JSON input is empty."
run_error_case sample.pdf "swift-markitdown: No converter is registered for pdf."
run_error_case sample.docx "swift-markitdown: No converter is registered for docx."
run_error_case sample.pptx "swift-markitdown: No converter is registered for pptx."
run_error_case sample.xlsx "swift-markitdown: No converter is registered for xlsx."
run_error_case empty.pdf "swift-markitdown: No converter is registered for pdf."
run_error_case empty.docx "swift-markitdown: No converter is registered for docx."
run_error_case empty.pptx "swift-markitdown: No converter is registered for pptx."
run_error_case empty.xlsx "swift-markitdown: No converter is registered for xlsx."
run_error_case unknown.bin "swift-markitdown: No converter is registered for unknown."
