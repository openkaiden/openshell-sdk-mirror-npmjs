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
}

teardown() {
  _common_teardown
}

@test "prints latest version to stdout" {
  create_mock npm 'echo "0.0.116"'

  run "${SCRIPTS_DIR}/fetch-latest-version.sh"
  assert_success
  assert_line "0.0.116"
}

@test "fails when npm view fails" {
  create_mock npm 'echo "Error" >&2; exit 1'

  run "${SCRIPTS_DIR}/fetch-latest-version.sh"
  assert_failure
}

@test "passes GITHUB_TOKEN as auth token" {
  create_mock npm 'echo "$@" > "${MOCK_BIN}/npm_args.log"; echo "1.0.0"'

  run "${SCRIPTS_DIR}/fetch-latest-version.sh"
  assert_success
  run cat "${MOCK_BIN}/npm_args.log"
  assert_output --partial "--//npm.pkg.github.com/:_authToken=test-token-123"
}

@test "works without GITHUB_TOKEN" {
  unset GITHUB_TOKEN

  create_mock npm 'echo "$@" > "${MOCK_BIN}/npm_args.log"; echo "1.0.0"'

  run "${SCRIPTS_DIR}/fetch-latest-version.sh"
  assert_success
  assert_line "1.0.0"
  run cat "${MOCK_BIN}/npm_args.log"
  refute_output --partial "_authToken"
}

@test "fails when npm returns empty output" {
  create_mock npm 'echo ""'

  run "${SCRIPTS_DIR}/fetch-latest-version.sh"
  assert_failure
  assert_output --partial "could not determine latest version"
}
