# Markdown, Notes, Sessions, and Git Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add native-first Markdown, quick-note, automatic project-session, and Git/diff workflows to Coffe.nvim under the `Cf` command namespace.

**Architecture:** Focused Lua modules expose small testable APIs and reuse the existing picker, UI, utility, project, and statusline layers. Persistent data stays under Neovim state except for the configurable note inbox, while Git subprocesses always use argument arrays.

**Tech Stack:** Neovim 0.11 Lua API, `vim.system`, Git CLI, existing Coffe dependency-free UI and test runner.

**Spec:** `docs/superpowers/specs/2026-09-11-markdown-notes-sessions-git-design.md`

## Global Constraints

- Public user commands start with `Cf`; removed `Coffe...` and runner commands must not be registered.
- No new required dependency and offline mode remains functional.
- Modified buffers and existing paths are never overwritten or discarded.
- Native `u`, `Ctrl-R`, `Ctrl-V`, `Ctrl-W`, `dd`, and `dw` remain untouched.

---

### Task 1: Configuration and command namespace

**Files:**
- Modify: `lua/coffe/config.lua`
- Modify: `lua/coffe/commands.lua`
- Modify: `lua/coffe/init.lua`
- Test: `tests/core.lua`

**Interfaces:**
- Produces: `config.markdown`, `config.notes`, `config.sessions`, new key definitions, and `Cf`-prefixed commands.

- [ ] Add failing assertions that `Cf`, `CfNote`, `CfMarkdown`, `CfGit`, `CfDiff`, and `CfDiffAll` exist and old or removed commands do not.
- [ ] Run `bash tests/run.sh` and confirm the assertions fail.
- [ ] Add grouped defaults and register only the new namespace, action mappings, and autocmd setup hooks.
- [ ] Run `bash tests/run.sh` and confirm namespace/config tests pass.

### Task 2: Markdown and quick notes

**Files:**
- Create: `lua/coffe/markdown.lua`
- Create: `lua/coffe/notes.lua`
- Modify: `lua/coffe/actions.lua`
- Test: `tests/core.lua`
- Test: `tests/workflows.lua`

**Interfaces:**
- Produces: `markdown.headings(buf)`, `markdown.toggle_checkbox(buf, row)`, `markdown.outline()`, `markdown.setup_buffer(buf)`, `notes.append(lines, path)`, and `notes.open()`.

- [ ] Add failing tests for ATX heading extraction, checkbox toggling, and timestamped note append to a configured temporary path.
- [ ] Run focused headless tests and confirm missing modules/functions fail.
- [ ] Implement parsing, buffer-local Markdown behavior, outline picker, editable note float, and safe append-on-write.
- [ ] Run the focused tests and confirm they pass.

### Task 3: Automatic project sessions

**Files:**
- Create: `lua/coffe/sessions.lua`
- Modify: `lua/coffe/projects.lua`
- Modify: `lua/coffe/init.lua`
- Test: `tests/core.lua`

**Interfaces:**
- Produces: `sessions.save(root)`, `sessions.restore(root)`, `sessions.can_restore()`, and `sessions.setup()`.
- Consumes: `projects.open(path)` saves the previous project then restores the target only when the workspace is clean.

- [ ] Add failing tests for saved file/cursor restoration, corrupt JSON, missing files, and preservation of modified buffers.
- [ ] Run the core test and confirm session APIs are missing.
- [ ] Implement hashed JSON state with atomic temporary-file replacement and guarded automatic hooks.
- [ ] Run core and smoke tests and confirm session behavior passes.

### Task 4: Git status and diff

**Files:**
- Create: `lua/coffe/git.lua`
- Modify: `lua/coffe/actions.lua`
- Modify: `lua/coffe/statusline.lua`
- Test: `tests/workflows.lua`

**Interfaces:**
- Produces: `git.root()`, `git.status(callback)`, `git.diff(path, staged)`, `git.open_status()`, `git.open_diff(path)`, `git.open_diff_all()`, and `git.summary()`.

- [ ] Create a temporary repository in tests and add failing assertions for paths with spaces, staged/unstaged/untracked states, and diff output.
- [ ] Run workflow tests and confirm the Git module is missing.
- [ ] Implement NUL-safe porcelain parsing, picker integration, read-only diff buffers, async cached status summary, and clear non-repository errors.
- [ ] Run workflow, core, and smoke tests and confirm Git behavior passes.

### Task 5: User-facing integration and full verification

**Files:**
- Modify: `lua/coffe/actions.lua`
- Modify: `lua/coffe/dashboard.lua`
- Modify: `lua/coffe/commands.lua`
- Modify: `coffe.lua`
- Modify: `examples/coffe_config.lua`
- Modify: `examples/lazy.lua`
- Modify: `README.md`
- Modify: `doc/coffe.txt`
- Modify: `AGENTS.md`
- Test: `tests/plugins.lua`

**Interfaces:**
- Consumes all public functions from Tasks 1-4 and exposes them through the palette, dashboard, mappings, help, and documentation.

- [ ] Add palette/help/dashboard assertions for Markdown, Notes, Git, and diff actions.
- [ ] Synchronize standalone and plugin configuration examples and document every `Cf` command.
- [ ] Run `bash tests/run.sh`.
- [ ] Run `./scripts/coffe --headless -i NONE '+luafile tests/plugins.lua'` when installed plugins are available.
- [ ] Run an isolated real Neovim UI smoke launch and inspect the Markdown, note, Git, and diff windows.
- [ ] Run `git diff --check` and review `git status --short` for unrelated changes.
