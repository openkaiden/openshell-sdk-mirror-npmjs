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
  unset GITHUB_ACTIONS

  # publish-version.sh calls siblings via SCRIPT_DIR, so we create a temp
  # scripts dir with the real publish-version.sh alongside mock siblings.
  FAKE_SCRIPTS_DIR=$(mktemp -d)
  export FAKE_SCRIPTS_DIR
  cp "${SCRIPTS_DIR}/publish-version.sh" "${FAKE_SCRIPTS_DIR}/"

  FAKE_TARBALL="${FAKE_SCRIPTS_DIR}/fake-package.tgz"
  export FAKE_TARBALL
  echo "fake" > "${FAKE_TARBALL}"

  # Default mock siblings
  cat > "${FAKE_SCRIPTS_DIR}/fetch-latest-version.sh" <<'STUB'
#!/usr/bin/env bash
echo "0.0.116"
STUB
  chmod +x "${FAKE_SCRIPTS_DIR}/fetch-latest-version.sh"

  cat > "${FAKE_SCRIPTS_DIR}/check-published.sh" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
  chmod +x "${FAKE_SCRIPTS_DIR}/check-published.sh"

  cat > "${FAKE_SCRIPTS_DIR}/repackage.sh" <<STUB
#!/usr/bin/env bash
echo "${FAKE_TARBALL}"
STUB
  chmod +x "${FAKE_SCRIPTS_DIR}/repackage.sh"

  # Mock npm via PATH
  create_mock npm 'echo "$@" > "${MOCK_BIN}/npm_publish_args.log"'
}

teardown() {
  _common_teardown
  rm -rf "${FAKE_SCRIPTS_DIR}"
}

@test "calls fetch-latest-version.sh when no version arg" {
  cat > "${FAKE_SCRIPTS_DIR}/check-published.sh" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
  chmod +x "${FAKE_SCRIPTS_DIR}/check-published.sh"

  cat > "${FAKE_SCRIPTS_DIR}/fetch-latest-version.sh" <<STUB
#!/usr/bin/env bash
echo "called" > "${MOCK_BIN}/fetch_called.log"
echo "0.0.116"
STUB
  chmod +x "${FAKE_SCRIPTS_DIR}/fetch-latest-version.sh"

  run "${FAKE_SCRIPTS_DIR}/publish-version.sh"
  assert_success
  [ -f "${MOCK_BIN}/fetch_called.log" ]
}

@test "uses provided version argument instead of fetching" {
  cat > "${FAKE_SCRIPTS_DIR}/check-published.sh" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
  chmod +x "${FAKE_SCRIPTS_DIR}/check-published.sh"

  cat > "${FAKE_SCRIPTS_DIR}/fetch-latest-version.sh" <<STUB
#!/usr/bin/env bash
echo "should-not-be-called" > "${MOCK_BIN}/fetch_called.log"
echo "0.0.116"
STUB
  chmod +x "${FAKE_SCRIPTS_DIR}/fetch-latest-version.sh"

  run "${FAKE_SCRIPTS_DIR}/publish-version.sh" "0.0.200"
  assert_success
  [ ! -f "${MOCK_BIN}/fetch_called.log" ]
}

@test "skips when version already published" {
  cat > "${FAKE_SCRIPTS_DIR}/check-published.sh" <<'STUB'
#!/usr/bin/env bash
echo "already published" >&2
exit 0
STUB
  chmod +x "${FAKE_SCRIPTS_DIR}/check-published.sh"

  run "${FAKE_SCRIPTS_DIR}/publish-version.sh" "0.0.116"
  assert_success
  assert_output --partial "already published"
  [ ! -f "${MOCK_BIN}/npm_publish_args.log" ]
}

@test "publishes when version not found" {
  run "${FAKE_SCRIPTS_DIR}/publish-version.sh" "0.0.116"
  assert_success

  [ -f "${MOCK_BIN}/npm_publish_args.log" ]
  run cat "${MOCK_BIN}/npm_publish_args.log"
  assert_output --partial "publish"
  assert_output --partial "${FAKE_TARBALL}"
  assert_output --partial "--access public"
}

@test "uses --provenance in GitHub Actions" {
  export GITHUB_ACTIONS="true"

  run "${FAKE_SCRIPTS_DIR}/publish-version.sh" "0.0.116"
  assert_success

  run cat "${MOCK_BIN}/npm_publish_args.log"
  assert_output --partial "--provenance"
}

@test "omits --provenance locally" {
  unset GITHUB_ACTIONS

  run "${FAKE_SCRIPTS_DIR}/publish-version.sh" "0.0.116"
  assert_success

  run cat "${MOCK_BIN}/npm_publish_args.log"
  refute_output --partial "--provenance"
}

@test "aborts on unexpected check-published error (exit 2)" {
  cat > "${FAKE_SCRIPTS_DIR}/check-published.sh" <<'STUB'
#!/usr/bin/env bash
echo "network timeout" >&2
exit 2
STUB
  chmod +x "${FAKE_SCRIPTS_DIR}/check-published.sh"

  run "${FAKE_SCRIPTS_DIR}/publish-version.sh" "0.0.116"
  assert_failure
  assert_output --partial "Error checking publication status"
  [ ! -f "${MOCK_BIN}/npm_publish_args.log" ]
}
