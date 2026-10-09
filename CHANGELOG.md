# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
