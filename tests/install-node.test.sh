#!/usr/bin/env bash
set -euo pipefail

TEST_ROOT="$(mktemp -d -t astrolabe-node-test)"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/node/bin"

cat > "$TEST_ROOT/bin/brew" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

case "$1" in
  install)
    exit "${TEST_INSTALL_STATUS:?}"
    ;;
  list)
    if [[ "${TEST_NODE_INSTALLED:?}" == "yes" ]]; then
      printf 'node@22 22.23.2_1\n'
      exit 0
    fi
    exit 1
    ;;
  --prefix)
    printf '%s\n' "${TEST_NODE_PREFIX:?}"
    ;;
  *)
    exit 64
    ;;
esac
SCRIPT

cat > "$TEST_ROOT/node/bin/node" <<'SCRIPT'
#!/usr/bin/env bash
exit "${TEST_NODE_STATUS:?}"
SCRIPT

chmod +x "$TEST_ROOT/bin/brew" "$TEST_ROOT/node/bin/node"

export PATH="$TEST_ROOT/bin:$PATH"
export TEST_NODE_PREFIX="$TEST_ROOT/node"

TEST_INSTALL_STATUS=0 \
TEST_NODE_INSTALLED=no \
TEST_NODE_STATUS=1 \
  bash scripts/ci/install-node.sh

TEST_INSTALL_STATUS=1 \
TEST_NODE_INSTALLED=yes \
TEST_NODE_STATUS=0 \
  bash scripts/ci/install-node.sh

if TEST_INSTALL_STATUS=1 \
  TEST_NODE_INSTALLED=no \
  TEST_NODE_STATUS=1 \
    bash scripts/ci/install-node.sh; then
  exit 1
fi

if TEST_INSTALL_STATUS=1 \
  TEST_NODE_INSTALLED=yes \
  TEST_NODE_STATUS=1 \
    bash scripts/ci/install-node.sh; then
  exit 1
fi
