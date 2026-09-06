# Coffe

Neovim 0.11+ Lua plugin and optional standalone configuration. Preserve native editing commands; add ergonomic shortcuts without replacing Ctrl-R, Ctrl-V, Ctrl-W or `u`.

- `lua/coffe/`: core setup, dashboard, project persistence, actions, lazy specs.
- `init.lua`: standalone entry; `coffe.lua`: user-facing configuration.
- `plugin/coffe.lua`: commands for plugin installations (setup is explicit).
- `scripts/coffe`: isolated launcher using NVIM_APPNAME=coffe; does not replace existing Neovim configuration.
- `examples/`: integration and optional terminal bindings.
- `tests/run.sh`: isolated headless behavior tests, no network needed.

Run `./scripts/coffe`; run tests with `bash tests/run.sh`; check whitespace with `git diff --check`.
Core must work without downloaded plugins. Optional lazy dependencies provide Neo-tree, Telescope, Gruvbox, completion, Git signs and key hints. External plugin changes need a real startup check when network is available.
Never modify the user's Neovim or terminal configuration automatically. Cmd shortcuts require terminal support; document portable alternatives. Use structured process arguments and escaped Ex paths. Never silently discard modified buffers or overwrite project files.
