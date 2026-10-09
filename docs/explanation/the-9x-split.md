# The 9.x split: from monolith back out 🔀

Why `space` ships as its own gem again, what changed at the boundary, and
what happens to your config and state. History with the seams showing — for
the migration *steps*, see [Install, update, and migrate from
8.x](../how-to/install-or-update.md).

## The arc: v1 → absorbed at 8.x → split at 9.0

The space tool's original home was this repo (the v1.0.0 era). It was then
absorbed into [space-architect](https://github.com/jetpks/space-architect),
where it rode along as the substrate of the Architect Loop through 8.0.0.
Version 9.0.0 undid the absorption: the space tool (`Space::Core`, binary
`space`) is extracted back into this repo — own gem, own version line —
restarting at **9.0.0**, one major above the 8.x line it left. The version
jump is deliberate: same tool, but a different package than the `space-cadet`
8.x era implies, and the XDG app-dir change (below) is a hard cut.

## Why split

The monolith tied three concerns together that evolve on different clocks:

- **The substrate** (`space`, `Space::Core`) — spaces, provisioning, config.
  Stable surface, slow-moving concepts.
- **The loop** (`architect`, in space-architect) — iteration machinery that
  changes with the agent tooling it orchestrates.
- **The tender** (`repo-tender`) — evergreen checkout maintenance, useful
  with or without either of the other two.

Splitting lets each gem version, release, and document on its own schedule,
and makes the dependency direction honest: the loop *runs on* spaces and
*softly depends on* the tender, rather than all three being one artifact.

## What moved at the boundary

- **Identity.** Gem `space-cadet`, binary `space`, module `Space::Core`,
  version line restarting at 9.0.0.
- **XDG app dirs.** Config and state moved from the `space-architect/` app
  dirs to `~/.config/space-cadet/` and `~/.local/state/space-cadet/`.
- **Fish integration internals.** The wrapper functions renamed to
  `__space_core_*` (from `__space_architect_*`); re-running `space shell fish
  install` after upgrading refreshes the files.
- **Vendored seams.** The subprocess shell, copy-on-write cloner, and git SCM
  seam (`Space::Core::Shell`, `Space::Core::Cloner`, `Space::Core::SCM::*`)
  are vendored into the gem — previously shared with the monolith's
  `Space::Src` engine.
- **Dependencies.** Trimmed to exactly what the space tool requires: `async`,
  `async-process`, `pastel`, `dry-cli`, `dry-monads`.

## The app-dir migration

The 9.0.0 cut meant 8.x users' `config.yml`/`state.yml` sat under the old
app name. 9.0.0 asked those users to move them by hand; **9.1.0 automated
it**: on first run (any real command — help and version queries stay
side-effect-free), the gem moves the substrate's config and state from
`space-architect/` to `space-cadet/` under a one-line stderr notice.

The migration is deliberately **file-level, not dir-level**: space-architect
9.x still keeps its session-sync cursor under the old state dir, so moving
the whole directory would break the monolith for anyone running both. Only
the substrate's two files move; the old dirs are left in place. It is
**no-clobber** — a new-space-cadet file present wins and the old file is
left alone, so there is no data loss either way — and **idempotent**, so
repeated runs are safe.

## What didn't change

The concepts: spaces are still date-prefixed self-describing directories,
resolved from `$PWD`; repos still provision from evergreen checkouts at
copy-on-write speed; config keys are the same six. If you knew `space` under
8.x, your hands are already right — only the gem's name and the app dirs
moved.
