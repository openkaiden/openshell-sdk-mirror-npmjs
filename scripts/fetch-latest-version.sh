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

REGISTRY="https://npm.pkg.github.com"
PACKAGE="@nvidia/openshell-sdk"

NPM_ARGS=("view" "${PACKAGE}" "dist-tags.latest" "--registry=${REGISTRY}")

if [ -n "${GITHUB_TOKEN:-}" ]; then
  NPM_ARGS+=("--//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}")
fi

echo "Fetching latest version of ${PACKAGE} from ${REGISTRY}..." >&2

VERSION=$(npm "${NPM_ARGS[@]}" 2>&2)

if [ -z "${VERSION}" ]; then
  echo "Error: could not determine latest version of ${PACKAGE}" >&2
  exit 1
fi

echo "${VERSION}"
