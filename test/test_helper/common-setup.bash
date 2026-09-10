#!/usr/bin/env bash
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

_common_setup() {
  # Resolve paths
  TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd -P)"
  SCRIPTS_DIR="$(cd "${TEST_DIR}/../scripts" && pwd -P)"

  # Load bats libraries — prefer vendored copies, fall back to bats_load_library (CI)
  if [ -f "${TEST_DIR}/test_helper/bats-support/load.bash" ]; then
    load "${TEST_DIR}/test_helper/bats-support/load.bash"
    load "${TEST_DIR}/test_helper/bats-assert/load.bash"
  elif type bats_load_library >/dev/null 2>&1; then
    bats_load_library bats-support
    bats_load_library bats-assert
  else
    echo "bats-support/bats-assert not found. Run: test/setup-libs.sh" >&2
    return 1
  fi

  # Create mock bin directory
  MOCK_BIN=$(mktemp -d)
  export PATH="${MOCK_BIN}:${PATH}"
  export MOCK_BIN
}

_common_teardown() {
  rm -rf "${MOCK_BIN}"
}

create_mock() {
  local cmd_name="$1"
  local script_body="$2"
  cat > "${MOCK_BIN}/${cmd_name}" <<MOCK_EOF
#!/usr/bin/env bash
${script_body}
MOCK_EOF
  chmod +x "${MOCK_BIN}/${cmd_name}"
}
