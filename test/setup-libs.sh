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

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
LIB_DIR="${SCRIPT_DIR}/test_helper"

BATS_SUPPORT_VERSION="0.3.0"
BATS_ASSERT_VERSION="2.1.0"

install_lib() {
  local name="$1"
  local version="$2"

  if [ -d "${LIB_DIR}/${name}" ]; then
    echo "${name} already installed." >&2
    return
  fi

  echo "Installing ${name}@${version}..." >&2
  local tmpdir
  tmpdir=$(mktemp -d)
  curl -sL "https://github.com/bats-core/${name}/archive/refs/tags/v${version}.tar.gz" \
    | tar xz -C "${tmpdir}"
  mv "${tmpdir}/${name}-${version}" "${LIB_DIR}/${name}"
  rm -rf "${tmpdir}"
  echo "${name} installed." >&2
}

install_lib "bats-support" "${BATS_SUPPORT_VERSION}"
install_lib "bats-assert" "${BATS_ASSERT_VERSION}"
