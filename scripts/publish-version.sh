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

if [ $# -ge 1 ]; then
  VERSION="$1"
else
  echo "No version specified, fetching latest..." >&2
  VERSION=$("${SCRIPT_DIR}/fetch-latest-version.sh")
fi

echo "Syncing version ${VERSION}..." >&2

set +e
"${SCRIPT_DIR}/check-published.sh" "${VERSION}"
CHECK_STATUS=$?
set -e

if [ ${CHECK_STATUS} -eq 0 ]; then
  echo "Version ${VERSION} already published. Nothing to do." >&2
  exit 0
elif [ ${CHECK_STATUS} -ne 1 ]; then
  echo "Error checking publication status (exit ${CHECK_STATUS}). Aborting." >&2
  exit 1
fi

TARBALL=$("${SCRIPT_DIR}/repackage.sh" "${VERSION}")
TARBALL_DIR=$(dirname "${TARBALL}")

cleanup() {
  rm -rf "${TARBALL_DIR}"
}
trap cleanup EXIT

PUBLISH_ARGS=("publish" "${TARBALL}" "--access" "public")

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  PUBLISH_ARGS+=("--provenance")
fi

echo "Publishing ${TARBALL}..." >&2
npm "${PUBLISH_ARGS[@]}"

echo "Successfully published @openkaiden/opnshll-sdk@${VERSION}" >&2
echo "${VERSION}"
