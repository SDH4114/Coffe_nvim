#!/bin/sh
set -eu

COFFE_TEST_ROOT=${COFFE_TEST_ROOT:?}
COFFE_TEST_TMP=${COFFE_TEST_TMP:?}
COFFE_INSTALL_TEST=$COFFE_TEST_TMP/installed-coffe
COFFE_BIN_TEST=$COFFE_TEST_TMP/bin
COFFE_CONFIG_TEST=$XDG_CONFIG_HOME/coffe/coffe.lua

COFFE_SOURCE_DIR=$COFFE_TEST_ROOT \
COFFE_INSTALL_DIR=$COFFE_INSTALL_TEST \
COFFE_BIN_DIR=$COFFE_BIN_TEST \
COFFE_SKIP_PLUGINS=1 \
sh "$COFFE_TEST_ROOT/install.sh"

test -L "$COFFE_BIN_TEST/coffe"
test -f "$COFFE_CONFIG_TEST"
test -f "$COFFE_INSTALL_TEST/init.lua"
COFFE_OFFLINE=1 "$COFFE_BIN_TEST/coffe" --headless \
  '+lua assert(require("coffe").config.config_file == vim.fn.fnamemodify(vim.fn.expand(vim.env.XDG_CONFIG_HOME .. "/coffe/coffe.lua"), ":p"))' \
  '+qa!'

printf '%s\n' 'PASS: one-command installer, launcher symlink, and external config'
