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

PACKAGE="@openkaiden/opnshll-sdk"
REGISTRY="https://registry.npmjs.org"

if [ $# -lt 1 ]; then
  echo "Usage: $(basename "$0") <version>" >&2
  exit 1
fi

VERSION="$1"

echo "Checking if ${PACKAGE}@${VERSION} exists on ${REGISTRY}..." >&2

set +e
OUTPUT=$(npm view "${PACKAGE}@${VERSION}" version --registry="${REGISTRY}" 2>&1)
EXIT_CODE=$?
set -e

if [ ${EXIT_CODE} -eq 0 ] && [ "${OUTPUT}" = "${VERSION}" ]; then
  echo "${PACKAGE}@${VERSION} is already published." >&2
  exit 0
fi

if echo "${OUTPUT}" | grep -qE "(E404|404 Not Found|is not in this registry)"; then
  echo "${PACKAGE}@${VERSION} is not published." >&2
  exit 1
fi

echo "Unexpected error checking ${PACKAGE}@${VERSION}:" >&2
echo "${OUTPUT}" >&2
exit 2
