#!/bin/sh
# Install the standalone Coffe.nvim distribution without touching ~/.config/nvim.
set -eu

COFFE_REPOSITORY=${COFFE_REPOSITORY:-https://github.com/SDH4114/Coffe_nvim.git}
COFFE_REF=${COFFE_REF:-main}
COFFE_INSTALL_DIR=${COFFE_INSTALL_DIR:-"${XDG_DATA_HOME:-$HOME/.local/share}/coffe.nvim"}
COFFE_BIN_DIR=${COFFE_BIN_DIR:-"$HOME/.local/bin"}
COFFE_CONFIG_DIR=${XDG_CONFIG_HOME:-"$HOME/.config"}/coffe
COFFE_CONFIG_FILE=$COFFE_CONFIG_DIR/coffe.lua
COFFE_COMMAND=$COFFE_BIN_DIR/coffe

say() { printf '%s\n' "$*"; }
fail() { printf 'Coffe: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "$1 is required."; }

need git
need nvim

COFFE_NVIM_VERSION=$(nvim --version | sed -n '1s/^NVIM v//p')
COFFE_NVIM_MAJOR=$(printf '%s' "$COFFE_NVIM_VERSION" | cut -d. -f1)
COFFE_NVIM_MINOR=$(printf '%s' "$COFFE_NVIM_VERSION" | cut -d. -f2)
case "$COFFE_NVIM_MAJOR:$COFFE_NVIM_MINOR" in
  ''|*[!0-9:]*) fail "could not read the Neovim version." ;;
esac
if [ "$COFFE_NVIM_MAJOR" -eq 0 ] && [ "$COFFE_NVIM_MINOR" -lt 11 ]; then
  fail "Neovim 0.11+ is required (found $COFFE_NVIM_VERSION)."
fi

if [ -n "${COFFE_SOURCE_DIR:-}" ]; then
  [ -d "$COFFE_SOURCE_DIR/lua/coffe" ] || fail "COFFE_SOURCE_DIR is not a Coffe.nvim checkout."
  [ ! -e "$COFFE_INSTALL_DIR" ] || fail "$COFFE_INSTALL_DIR already exists."
  mkdir -p "$(dirname -- "$COFFE_INSTALL_DIR")"
  cp -R "$COFFE_SOURCE_DIR" "$COFFE_INSTALL_DIR"
  say "Installed Coffe.nvim from $COFFE_SOURCE_DIR"
elif [ -d "$COFFE_INSTALL_DIR/.git" ]; then
  COFFE_CURRENT_REMOTE=$(git -C "$COFFE_INSTALL_DIR" remote get-url origin 2>/dev/null || true)
  [ "$COFFE_CURRENT_REMOTE" = "$COFFE_REPOSITORY" ] || fail "$COFFE_INSTALL_DIR belongs to another repository."
  [ -z "$(git -C "$COFFE_INSTALL_DIR" status --porcelain)" ] || fail "$COFFE_INSTALL_DIR has local changes; update cancelled."
  say "Updating Coffe.nvim..."
  # Keep the existing shallow boundary so FETCH_HEAD remains connected to HEAD.
  git -C "$COFFE_INSTALL_DIR" fetch origin "$COFFE_REF"
  git -C "$COFFE_INSTALL_DIR" merge --ff-only FETCH_HEAD
elif [ -e "$COFFE_INSTALL_DIR" ]; then
  fail "$COFFE_INSTALL_DIR already exists and is not a Coffe.nvim Git checkout."
else
  mkdir -p "$(dirname -- "$COFFE_INSTALL_DIR")"
  say "Downloading Coffe.nvim..."
  git clone --depth 1 --branch "$COFFE_REF" "$COFFE_REPOSITORY" "$COFFE_INSTALL_DIR"
fi

mkdir -p "$COFFE_CONFIG_DIR" "$COFFE_BIN_DIR"
if [ ! -f "$COFFE_CONFIG_FILE" ]; then
  cp "$COFFE_INSTALL_DIR/coffe.lua" "$COFFE_CONFIG_FILE"
  say "Created config: $COFFE_CONFIG_FILE"
else
  say "Kept existing config: $COFFE_CONFIG_FILE"
fi

if [ -e "$COFFE_COMMAND" ] && [ ! -L "$COFFE_COMMAND" ]; then
  fail "$COFFE_COMMAND already exists and is not a symlink."
fi
ln -sfn "$COFFE_INSTALL_DIR/scripts/coffe" "$COFFE_COMMAND"

if [ "${COFFE_SKIP_PLUGINS:-0}" != 1 ]; then
  say "Installing the default plugins..."
  if ! COFFE_CONFIG_FILE=$COFFE_CONFIG_FILE "$COFFE_COMMAND" --headless \
    '+lua if not pcall(require, "lazy") then vim.cmd("cquit 1") end' \
    "+Lazy! sync" "+qa"; then
    fail "default plugin installation failed. Check the network connection and run this installer again."
  fi
fi

say ""
say "Coffe.nvim is ready. Run:"
say "  $COFFE_COMMAND"
case ":$PATH:" in
  *:"$COFFE_BIN_DIR":*) say "Or simply: coffe" ;;
  *)
    say ""
    say "$COFFE_BIN_DIR is not in PATH. Add this line to your shell config if you want to run just 'coffe':"
    say "  export PATH=\"$COFFE_BIN_DIR:\$PATH\""
    ;;
esac
if ! command -v rg >/dev/null 2>&1; then
  say ""
  say "Optional: install ripgrep for fast file and text search (brew install ripgrep)."
fi
