#!/usr/bin/env bats
#
# Copyright (C) 2026 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

setup() {
  load 'test_helper/common-setup'
  _common_setup
  export GITHUB_TOKEN="test-token-123"

  # Create a fixture tarball that mimics what npm pack produces
  FIXTURE_DIR=$(mktemp -d)
  export FIXTURE_DIR
  mkdir -p "${FIXTURE_DIR}/package"
  cat > "${FIXTURE_DIR}/package/package.json" <<'EOF'
{
  "name": "@nvidia/openshell-sdk",
  "version": "0.0.116",
  "description": "OpenShell SDK",
  "main": "index.js",
  "license": "Apache-2.0",
  "dependencies": {
    "some-dep": "^1.0.0"
  }
}
EOF
  echo "module.exports = {};" > "${FIXTURE_DIR}/package/index.js"
  tar czf "${FIXTURE_DIR}/nvidia-openshell-sdk-0.0.116.tgz" -C "${FIXTURE_DIR}" package/

  # Mock npm pack to copy our fixture tarball instead of downloading
  create_mock npm "$(cat <<MOCK
for arg in "\$@"; do
  if [[ "\$arg" == --pack-destination=* ]]; then
    DEST="\${arg#--pack-destination=}"
    cp "${FIXTURE_DIR}/nvidia-openshell-sdk-0.0.116.tgz" "\${DEST}/"
    echo "nvidia-openshell-sdk-0.0.116.tgz"
    exit 0
  fi
done
echo "Error: --pack-destination not found" >&2
exit 1
MOCK
)"
}

teardown() {
  _common_teardown
  rm -rf "${FIXTURE_DIR}"
}

get_last_line() {
  echo "${lines[${#lines[@]}-1]}"
}

run_repackage_and_extract() {
  run "${SCRIPTS_DIR}/repackage.sh" "0.0.116"
  assert_success

  OUTPUT_TARBALL="$(get_last_line)"
  EXTRACT_DIR=$(mktemp -d)
  tar xzf "${OUTPUT_TARBALL}" -C "${EXTRACT_DIR}"
}

@test "changes package name" {
  run_repackage_and_extract

  run jq -r '.name' "${EXTRACT_DIR}/package/package.json"
  assert_output "@openkaiden/opnshll-sdk"
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "sets publishConfig" {
  run_repackage_and_extract

  run jq -r '.publishConfig.access' "${EXTRACT_DIR}/package/package.json"
  assert_output "public"
  run jq -r '.publishConfig.registry' "${EXTRACT_DIR}/package/package.json"
  assert_output "https://registry.npmjs.org"
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "sets repository URL" {
  run_repackage_and_extract

  run jq -r '.repository.url' "${EXTRACT_DIR}/package/package.json"
  assert_output "https://github.com/openkaiden/openshell-sdk-mirror-npmjs"
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "preserves version" {
  run_repackage_and_extract

  run jq -r '.version' "${EXTRACT_DIR}/package/package.json"
  assert_output "0.0.116"
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "preserves dependencies" {
  run_repackage_and_extract

  run jq -r '.dependencies["some-dep"]' "${EXTRACT_DIR}/package/package.json"
  assert_output "^1.0.0"
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "replaces README with mirror notice" {
  run_repackage_and_extract

  run cat "${EXTRACT_DIR}/package/README.md"
  assert_output --partial "automated mirror"
  assert_output --partial "@openkaiden/opnshll-sdk"
  refute_output --partial "@nvidia"
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "outputs tarball path to stdout" {
  run "${SCRIPTS_DIR}/repackage.sh" "0.0.116"
  assert_success

  OUTPUT_TARBALL="$(get_last_line)"
  [[ "${OUTPUT_TARBALL}" == *.tgz ]]
  [ -f "${OUTPUT_TARBALL}" ]
  rm -rf "$(dirname "${OUTPUT_TARBALL}")"
}

@test "excludes macOS resource fork files" {
  run_repackage_and_extract

  DOTFILES=$(find "${EXTRACT_DIR}" -name '._*' | wc -l | tr -d ' ')
  [ "${DOTFILES}" -eq 0 ]
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "fails when jq is broken" {
  # Shadow real jq with one that always fails
  create_mock jq 'echo "jq: command failed" >&2; exit 1'

  run "${SCRIPTS_DIR}/repackage.sh" "0.0.116"
  assert_failure
}

@test "requires version argument" {
  run "${SCRIPTS_DIR}/repackage.sh"
  assert_failure 1
  assert_output --partial "Usage:"
}
