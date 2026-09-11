#!/bin/sh
set -eu
COFFE_TEST_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
COFFE_TEST_TMP=$(mktemp -d)
export COFFE_TEST_ROOT COFFE_TEST_TMP
export XDG_CONFIG_HOME="$COFFE_TEST_TMP/config" XDG_DATA_HOME="$COFFE_TEST_TMP/data"
export XDG_STATE_HOME="$COFFE_TEST_TMP/state" XDG_CACHE_HOME="$COFFE_TEST_TMP/cache"
export COFFE_OFFLINE=1 NVIM_APPNAME=coffe-test
sh "$COFFE_TEST_ROOT/tests/install.sh"
nvim --headless -u NONE -l "$COFFE_TEST_ROOT/tests/core.lua"
nvim --headless -u "$COFFE_TEST_ROOT/init.lua" '+lua assert(require("coffe").config.theme == "gruvbox")' '+qa!'
cd "$COFFE_TEST_ROOT"
nvim --headless -u NONE -l "$COFFE_TEST_ROOT/tests/smoke.lua"
nvim --headless -u NONE -l "$COFFE_TEST_ROOT/tests/workflows.lua"
nvim --headless -u NONE -l "$COFFE_TEST_ROOT/tests/features.lua"
