# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [9.2.0] - 2026-10-16

### Added

- **`--trust-host-key` flag on `space repo add` and `space new`.** Appends
  `-o StrictHostKeyChecking=accept-new` to the ssh command used for clones
  (TOFU: first-contact host keys are accepted automatically; *changed* keys
  still fail verification, so MITM protection is retained). Using the flag
  prints a stderr warning before fetching begins. `space` never sets
  `StrictHostKeyChecking=no`.

### Changed

- **ssh clones never prompt.** Every network clone now runs the child with
  `GIT_SSH_COMMAND` set to `<inherited GIT_SSH_COMMAND, or "ssh"> -o
  BatchMode=yes` (options appended after an inherited value, assumed
  ssh-compatible; git ignores the variable for https URLs), so host-key,
  passphrase, and password prompts fail fast instead of hanging behind the
  progress spinner. A failure containing `Host key verification failed`
  surfaces guidance naming `--trust-host-key` and `known_hosts`; every other
  failure surfaces the raw stderr as before.
- **Idempotent `space repo add` / `space new -r`.** Re-adding an
  already-tracked repo is a no-op success (`Already present: …`, no clone,
  no new `space.yaml` entry), and an untracked destination that already
  contains a `.git` directory is adopted — mise-trusted and registered with
  no fetch (`Registered existing checkout: …`) — so the corrected rerun
  after a partially-failed batch succeeds instead of erroring on the
  orphaned destination. A destination without `.git` is still refused
  (not-a-git-repository error), path/name collisions with a *different*
  tracked repo still error, and registration remains all-or-nothing: any
  fetch failure exits non-zero and registers nothing.

## [9.1.0] - 2026-10-10

### Added

- **Automatic 8.x app-dir migration.** `Space::Core::Migration` moves the
  substrate's `config.yml` and `state.yml` from the 8.x monolith's
  `space-architect/` XDG dirs to this gem's `space-cadet/` dirs on first run
  (invoked from `CLI.run` before dispatch — the repo-tender seam, no-clobber,
  idempotent, one-line notice on stderr). File-level, not dir-level:
  space-architect 9.0.0 still keeps its `session-sync.yaml` cursor under the
  old state dir, so it is left untouched. A new-space-cadet file present
  wins and the old file is left in place — no data loss either way. This
  automates the manual migration the 9.0.0 entry asked for.
- **Host-branded help header.** `Space::Core::CLI::Help.product_name` /
  `product_version` (set alongside `trailing_group_label`) let a host binary
  sharing the renderer — the `architect` binary — brand its root help header
  with its own name and version instead of the substrate's. Unset, the
  header renders `space-cadet <version>` exactly as before.

## [9.0.0] - 2026-10-09

### Changed

- **Extracted from space-architect 8.0.0.** The space tool (`Space::Core`,
  binary `space`) is split back out of
  [jetpks/space-architect](https://github.com/jetpks/space-architect) into its
  own repo, gem, and version line — undoing the v1.0.0-era absorption. The gem
  is `space-cadet`, the binary is `space`, the module stays `Space::Core`, and
  the version restarts at 9.0.0 (one major above the 8.x line it left).
- The fish shell integration's internals are renamed to the gem's own identity:
  `__space_core_*` functions and the `__SPACE_CORE_VERSION__` compat-token
  placeholder (was `__space_architect_*` / `__SPACE_ARCHITECT_VERSION__`).
  Re-run `space shell fish install` after upgrading.
- XDG config/state now live under `~/.config/space-cadet/` and
  `~/.local/state/space-cadet/` (was `space-architect/`). Run `space init` and
  migrate any custom `config.yml`/`state.yml` across.
- The engine's subprocess shell, copy-on-write cloner, and git SCM seam
  (`Space::Core::Shell`, `Space::Core::Cloner`, `Space::Core::SCM::*`) are
  vendored into the gem — previously shared with the space-architect monolith's
  `Space::Src` engine.
- Dependencies trimmed to exactly what the space tool requires: `async`,
  `async-process`, `pastel`, `dry-cli`, `dry-monads`.

[9.0.0]: https://github.com/jetpks/space-cadet/blob/main/CHANGELOG.md
