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

SOURCE_PACKAGE="@nvidia/openshell-sdk"
TARGET_PACKAGE="@openkaiden/opnshll-sdk"
SOURCE_REGISTRY="https://npm.pkg.github.com"
TARGET_REGISTRY="https://registry.npmjs.org"
MIRROR_REPO="https://github.com/openkaiden/openshell-sdk-mirror-npmjs"

if [ $# -lt 1 ]; then
  echo "Usage: $(basename "$0") <version>" >&2
  exit 1
fi

VERSION="$1"

for cmd in jq npm tar; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: '${cmd}' is required but not found in PATH." >&2
    exit 1
  fi
done

WORK_DIR=$(mktemp -d)
cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

echo "Downloading ${SOURCE_PACKAGE}@${VERSION} from ${SOURCE_REGISTRY}..." >&2

NPM_PACK_ARGS=("pack" "${SOURCE_PACKAGE}@${VERSION}" "--registry=${SOURCE_REGISTRY}" "--pack-destination=${WORK_DIR}")

if [ -n "${GITHUB_TOKEN:-}" ]; then
  NPM_PACK_ARGS+=("--//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}")
fi

npm "${NPM_PACK_ARGS[@]}" >&2

echo "Extracting tarball..." >&2
COPYFILE_DISABLE=1 tar xzf "${WORK_DIR}"/*.tgz -C "${WORK_DIR}"

PACKAGE_JSON="${WORK_DIR}/package/package.json"
if [ ! -f "${PACKAGE_JSON}" ]; then
  echo "Error: package.json not found in extracted tarball." >&2
  exit 1
fi

echo "Rewriting package.json..." >&2
jq \
  --arg name "${TARGET_PACKAGE}" \
  --arg registry "${TARGET_REGISTRY}" \
  --arg repo "${MIRROR_REPO}" \
  '.name = $name |
   .publishConfig = {"access": "public", "registry": $registry} |
   .repository = {"type": "git", "url": $repo}' \
  "${PACKAGE_JSON}" > "${PACKAGE_JSON}.tmp"
mv "${PACKAGE_JSON}.tmp" "${PACKAGE_JSON}"

echo "Replacing README..." >&2
cat > "${WORK_DIR}/package/README.md" <<'README'
# @openkaiden/opnshll-sdk

This package is an automated mirror published to npmjs for convenience.

See the [source repository](https://github.com/openkaiden/openshell-sdk-mirror-npmjs) for details.
README

OUTPUT_DIR=$(mktemp -d)
OUTPUT_TARBALL="${OUTPUT_DIR}/openkaiden-opnshll-sdk-${VERSION}.tgz"

echo "Creating repackaged tarball..." >&2
COPYFILE_DISABLE=1 tar czf "${OUTPUT_TARBALL}" -C "${WORK_DIR}" package/

trap - EXIT
rm -rf "${WORK_DIR}"

echo "${OUTPUT_TARBALL}"
