# Install, update, and migrate from 8.x 📦

How to get the `space` binary onto your machine, keep it current, and come
across from the space-architect 8.x monolith with your config and state
intact.

## Install the gem

```sh
gem install space-cadet
```

or in a project using Bundler:

```ruby
gem "space-cadet"
```

```sh
bundle install
```

The gem is `space-cadet`; it installs one executable, `space`, over the
`Space::Core` library. Verify with:

```sh
space version
```

## Update to a newer version

```sh
gem update space-cadet        # or: bundle update space-cadet
space version                 # confirm the number moved
```

New versions are announced in [CHANGELOG.md](../../CHANGELOG.md).

## Migrate from the 8.x monolith

Up to 8.0.0, the space tool (`Space::Core`, binary `space`) shipped inside
[jetpks/space-architect](https://github.com/jetpks/space-architect), and its
config and state lived under the `space-architect` XDG app dirs. Since 9.0.0
the tool is this standalone gem, and since **9.1.0 the migration is
automatic** — there is nothing to hand-edit.

Install `space-cadet` (see above), uninstall the 8.x monolith when you're
fully off it (space-architect's own docs carry its upgrade guide), then run
any `space` command:

```sh
space list
```

On the first run, `space-cadet` moves the substrate's files — and only these
files — from the old app dirs:

| File | Old (8.x) | New (9.x) |
|---|---|---|
| Config | `~/.config/space-architect/config.yml` | `~/.config/space-cadet/config.yml` |
| State | `~/.local/state/space-architect/state.yml` | `~/.local/state/space-cadet/state.yml` |

A one-line notice on stderr tells you what moved:

```text
space-cadet: migrated config/state from space-architect
```

Properties worth knowing:

- **No-clobber.** If a new `space-cadet` file already exists, it wins and the
  old file is left in place — no data loss either way.
- **File-level, not dir-level.** space-architect 9.x keeps its own session-sync
  cursor under the old state dir; the migration deliberately leaves the old
  directories alone and moves only the substrate's `config.yml`/`state.yml`.
- **Idempotent.** Repeated runs are safe; nothing to undo.
- **Side-effect-free queries skip it.** Bare `space`, `space --help`, and
  `space version` don't trigger a migration.

If you set a custom `config.yml` under 8.x, it lands at the new path with your
values intact — check `space config show` to confirm.
