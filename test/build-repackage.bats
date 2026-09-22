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

  # Create a fixture SDK directory that mimics a built TypeScript SDK
  SDK_DIR=$(mktemp -d)
  export SDK_DIR
  cat > "${SDK_DIR}/package.json" <<'EOF'
{
  "name": "@nvidia/openshell-sdk",
  "version": "0.1.0",
  "description": "OpenShell SDK",
  "main": "dist/index.js",
  "license": "Apache-2.0",
  "dependencies": {
    "@bufbuild/protobuf": "^2.2.3",
    "@connectrpc/connect": "^2.0.0"
  }
}
EOF
  mkdir -p "${SDK_DIR}/dist"
  echo "module.exports = {};" > "${SDK_DIR}/dist/index.js"
}

teardown() {
  _common_teardown
  rm -rf "${SDK_DIR}"
}

get_last_line() {
  echo "${lines[${#lines[@]}-1]}"
}

run_build_repackage_and_extract() {
  run "${SCRIPTS_DIR}/build-repackage.sh" "${SDK_DIR}" "0.0.0-20260918-abc1234"
  assert_success

  OUTPUT_TARBALL="$(get_last_line)"
  EXTRACT_DIR=$(mktemp -d)
  tar xzf "${OUTPUT_TARBALL}" -C "${EXTRACT_DIR}"
}

@test "changes package name" {
  run_build_repackage_and_extract

  run jq -r '.name' "${EXTRACT_DIR}/package/package.json"
  assert_output "@openkaiden/opnshll-sdk"
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "sets version" {
  run_build_repackage_and_extract

  run jq -r '.version' "${EXTRACT_DIR}/package/package.json"
  assert_output "0.0.0-20260918-abc1234"
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "sets publishConfig" {
  run_build_repackage_and_extract

  run jq -r '.publishConfig.access' "${EXTRACT_DIR}/package/package.json"
  assert_output "public"
  run jq -r '.publishConfig.registry' "${EXTRACT_DIR}/package/package.json"
  assert_output "https://registry.npmjs.org"
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "sets repository URL" {
  run_build_repackage_and_extract

  run jq -r '.repository.url' "${EXTRACT_DIR}/package/package.json"
  assert_output "https://github.com/openkaiden/openshell-sdk-mirror-npmjs"
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "preserves dependencies" {
  run_build_repackage_and_extract

  run jq -r '.dependencies["@bufbuild/protobuf"]' "${EXTRACT_DIR}/package/package.json"
  assert_output "^2.2.3"
  run jq -r '.dependencies["@connectrpc/connect"]' "${EXTRACT_DIR}/package/package.json"
  assert_output "^2.0.0"
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "replaces README with mirror notice" {
  run_build_repackage_and_extract

  run cat "${EXTRACT_DIR}/package/README.md"
  assert_output --partial "automated mirror"
  assert_output --partial "@openkaiden/opnshll-sdk"
  refute_output --partial "@nvidia"
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "outputs tarball path to stdout" {
  run "${SCRIPTS_DIR}/build-repackage.sh" "${SDK_DIR}" "0.0.0-20260918-abc1234"
  assert_success

  OUTPUT_TARBALL="$(get_last_line)"
  [[ "${OUTPUT_TARBALL}" == *.tgz ]]
  [ -f "${OUTPUT_TARBALL}" ]
  rm -rf "$(dirname "${OUTPUT_TARBALL}")"
}

@test "excludes macOS resource fork files" {
  run_build_repackage_and_extract

  DOTFILES=$(find "${EXTRACT_DIR}" -name '._*' | wc -l | tr -d ' ')
  [ "${DOTFILES}" -eq 0 ]
  rm -rf "${EXTRACT_DIR}" "$(dirname "${OUTPUT_TARBALL}")"
}

@test "fails when jq is broken" {
  create_mock jq 'echo "jq: command failed" >&2; exit 1'

  run "${SCRIPTS_DIR}/build-repackage.sh" "${SDK_DIR}" "0.0.0-20260918-abc1234"
  assert_failure
}

@test "requires sdk-directory argument" {
  run "${SCRIPTS_DIR}/build-repackage.sh"
  assert_failure 1
  assert_output --partial "Usage:"
}

@test "requires version argument" {
  run "${SCRIPTS_DIR}/build-repackage.sh" "${SDK_DIR}"
  assert_failure 1
  assert_output --partial "Usage:"
}
