#!/usr/bin/env bash
# Copyright 2017 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
#
# This script will build cmd and calculate hash for each
# (PROJECT_BUILD_PLATFORMS, PROJECT_BUILD_ARCHS) pair.
# PROJECT_BUILD_PLATFORMS="linux" PROJECT_BUILD_ARCHS="amd64" ./hack/build-all.bash
# can be called to build only for linux-amd64

set -e

CMD_NAME=s5cmd
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
VERSION=$(git describe --tags --dirty)
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null)
DATE=$(date "+%Y-%m-%d")
BUILD_PLATFORM=$(uname -a | awk '{print tolower($1);}')
IMPORT_DURING_SOLVE=${IMPORT_DURING_SOLVE:-false}

if [[ "$(pwd)" != "${PROJECT_ROOT}" ]]; then
  echo "you are not in the root of the repo" 1>&2
  echo "please cd to ${PROJECT_ROOT} before running this script" 1>&2
  exit 1
fi

GO_BUILD_CMD="go build -a -installsuffix cgo"
GO_BUILD_LDFLAGS="-s -w -X main.commitHash=${COMMIT_HASH} -X main.buildDate=${DATE} -X main.version=${VERSION} -X main.flagImportDuringSolve=${IMPORT_DURING_SOLVE}"

if [[ -z "${PROJECT_BUILD_PLATFORMS}" ]]; then
    PROJECT_BUILD_PLATFORMS="linux windows darwin"
fi

if [[ -z "${PROJECT_BUILD_ARCHS}" ]]; then
    # PROJECT_BUILD_ARCHS="amd64 386 ppc64 ppc64le s390x arm arm64"
    PROJECT_BUILD_ARCHS="amd64 386"
fi

mkdir -p "${PROJECT_ROOT}/release"

for OS in ${PROJECT_BUILD_PLATFORMS[@]}; do
  for ARCH in ${PROJECT_BUILD_ARCHS[@]}; do
    NAME="${CMD_NAME}-${OS}-${ARCH}"
    if [[ "${OS}" == "windows" ]]; then
      NAME="${NAME}.exe"
    fi

    # Enable CGO if building for OS X on OS X; see
    # https://github.com/golang/dep/issues/1838 for details.
    if [[ "${OS}" == "darwin" && "${BUILD_PLATFORM}" == "darwin" ]]; then
      CGO_ENABLED=1
    else
      CGO_ENABLED=0
    fi
    if [[ "${ARCH}" == "ppc64" || "${ARCH}" == "ppc64le" || "${ARCH}" == "s390x" || "${ARCH}" == "arm" || "${ARCH}" == "arm64" ]] && [[ "${OS}" != "linux" ]]; then
        # ppc64, ppc64le, s390x, arm and arm64 are only supported on Linux.
        echo "Building for ${OS}/${ARCH} not supported."
    elif [[ "${ARCH}" == "386" && "${OS}" == "darwin" ]]; then
        echo "Building for ${OS}/${ARCH} not supported."
    else
        echo "Building for ${OS}/${ARCH} with CGO_ENABLED=${CGO_ENABLED}"
        GOARCH=${ARCH} GOOS=${OS} CGO_ENABLED=${CGO_ENABLED} ${GO_BUILD_CMD} -ldflags "${GO_BUILD_LDFLAGS}"\
            -o "${PROJECT_ROOT}/release/${NAME}" ./
        pushd "${PROJECT_ROOT}/release" > /dev/null
        shasum -a 256 "${NAME}" > "${NAME}.sha256"
        popd > /dev/null
    fi
  done
done
