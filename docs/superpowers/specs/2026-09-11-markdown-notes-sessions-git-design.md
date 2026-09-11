# Coffe.nvim Markdown, Notes, Sessions, and Git Design

## Goal

Extend Coffe.nvim with practical terminal-first workflows for Markdown writers and programmers while preserving native Neovim behavior and the dependency-free core.

## Command Interface

Neovim requires user commands to start with an uppercase character. All public Coffe commands therefore use the `Cf` prefix:

- `:CfNote` opens a quick-note editor and appends the submitted entry to the configured inbox.
- `:CfMarkdown` opens an outline of the current Markdown file.
- `:CfGit` opens the repository status picker.
- `:CfDiff` opens the diff for the current file.
- `:CfDiffAll` opens the diff for the repository.
- Existing public commands are renamed from `Coffe...` to `Cf...`, with `:Cf` as the main dispatcher.

There is no command runner and no public Problems, Symbols, Tasks, SessionSave, or SessionRestore command.

## Markdown Workflow

`coffe.markdown` provides a dependency-free outline by parsing ATX headings from the current buffer. Selecting an item jumps to its line. Markdown buffers receive buffer-local mappings for toggling task checkboxes and following file or heading links. Writer-friendly wrapping is configurable and does not replace native editing keys.

## Quick Notes

`coffe.notes` opens a real editable floating buffer. Saving the buffer appends a timestamped entry to `notes.path`; closing an unchanged note writes nothing. Parent directories are created only when the user saves their first note. Tests override the path so user files are never touched.

## Automatic Project Sessions

`coffe.sessions` stores project state under `stdpath('state')/coffe/sessions`. It records listed file buffers and cursor positions. Sessions save automatically before exit and before changing projects, and restore automatically when Coffe opens a project into a clean workspace. Modified buffers are never closed, replaced, or discarded. Missing files and corrupt session data are ignored safely.

No manual session commands are exposed.

## Git and Diff

`coffe.git` invokes Git with argument arrays and explicit working directories. `:CfGit` parses NUL-delimited porcelain output so paths containing spaces are safe. The picker shows staged, unstaged, renamed, and untracked files; selecting an entry opens it, and preview opens its diff.

Diff views use read-only scratch buffers with `diff` filetype. `:CfDiff` scopes the diff to the current file, while `:CfDiffAll` shows staged and unstaged repository changes. The statusline adds the branch and a compact changed-file count. Non-repositories and missing Git produce clear warnings rather than errors.

## Integration

All new actions appear in the command palette, dashboard where appropriate, keyboard guide, README, help documentation, standalone config, and examples. Public defaults remain compact. Existing user mappings take priority, and native `u`, `Ctrl-R`, `Ctrl-V`, `Ctrl-W`, `dd`, and `dw` remain untouched.

## Verification

Tests cover Markdown outline and checkbox behavior, note persistence, safe automatic session restore, Git status parsing, file and repository diff, command registration, corrupt state, paths containing spaces, and absence of removed commands. Final verification runs the offline suite, a real interactive Neovim launch for UI behavior, plugin integration where available, and `git diff --check`.
