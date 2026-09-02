#!/usr/bin/env bash
set -euo pipefail

TEST_FIXTURES="$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"

export PATH="${TEST_FIXTURES}/bin:${PATH}"
export TEST_NODE_PREFIX="${TEST_FIXTURES}/node"

env TEST_INSTALL_STATUS=0 TEST_NODE_INSTALLED=no TEST_NODE_STATUS=1 \
  bash scripts/ci/install-node.sh

env TEST_INSTALL_STATUS=1 TEST_NODE_INSTALLED=yes TEST_NODE_STATUS=0 \
  bash scripts/ci/install-node.sh

if env TEST_INSTALL_STATUS=1 TEST_NODE_INSTALLED=no TEST_NODE_STATUS=1 \
   bash scripts/ci/install-node.sh
then
  exit 1
fi

if env TEST_INSTALL_STATUS=1 TEST_NODE_INSTALLED=yes TEST_NODE_STATUS=1 \
   bash scripts/ci/install-node.sh
then
  exit 1
fi
