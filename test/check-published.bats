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
}

teardown() {
  _common_teardown
}

@test "exits 0 when version exists" {
  create_mock npm 'echo "0.0.116"'

  run "${SCRIPTS_DIR}/check-published.sh" "0.0.116"
  assert_success
  assert_output --partial "already published"
}

@test "exits 1 when version not found (E404)" {
  create_mock npm 'echo "npm ERR! code E404" >&2; echo "E404 - Not Found"; exit 1'

  run "${SCRIPTS_DIR}/check-published.sh" "0.0.999"
  assert_failure 1
  assert_output --partial "is not published"
}

@test "exits 1 when package not in registry" {
  create_mock npm 'echo "is not in this registry" >&2; echo "is not in this registry"; exit 1'

  run "${SCRIPTS_DIR}/check-published.sh" "0.0.999"
  assert_failure 1
  assert_output --partial "is not published"
}

@test "exits 2 on unexpected error" {
  create_mock npm 'echo "npm ERR! network timeout" >&2; echo "network timeout"; exit 1'

  run "${SCRIPTS_DIR}/check-published.sh" "0.0.116"
  assert_failure 2
  assert_output --partial "Unexpected error"
}

@test "requires version argument" {
  run "${SCRIPTS_DIR}/check-published.sh"
  assert_failure 1
  assert_output --partial "Usage:"
}

@test "handles 404 for entire package (first-ever publish)" {
  create_mock npm 'echo "404 Not Found" >&2; echo "404 Not Found"; exit 1'

  run "${SCRIPTS_DIR}/check-published.sh" "0.0.1"
  assert_failure 1
  assert_output --partial "is not published"
}
