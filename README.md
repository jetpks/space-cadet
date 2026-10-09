# Space Cadet 🪐

[![Gem Version](https://badge.fury.io/rb/space-cadet.svg)](https://badge.fury.io/rb/space-cadet)

> **Task-scoped project workspaces — for humans and their agents!** ✨🌌

`space-cadet` is a Ruby gem for **spaces** — task-scoped project workspaces
that hold repos, notes, and artifacts under one obvious filesystem root. One
binary, **`space`**, over the `Space::Core` library. It pairs with
[jetpks/space-architect](https://github.com/jetpks/space-architect) (the
Architect Loop, which runs on top of spaces) and
[jetpks/repo-tender](https://github.com/jetpks/repo-tender) (which tends the
evergreen checkouts spaces provision from).

**Lineage:** this repo is the space tool's original home (the v1.0.0 era); the
tool was absorbed into space-architect (up to 8.0.0) and is extracted back out
here as of 9.0.0.

## What's a space? 🪐

A space is just a regular directory with a tiny YAML identity file and room for
everything a task needs:

```text
~/architect/spaces/20260531-name-of-space/
  space.yaml        # identity: id, title, status, repos, notes, tags
  README.md
  repos/            # cloned (or copy-on-write'd) repositories
  notes/            # scratch, prompts, logs
  architecture/     # project files when the space runs an Architect project
  build/            # OCI contexts + scratch (build/oci/)
  tmp/              # workspace-local temp — use this instead of /tmp
```

Run a command from anywhere inside a space and it just works — `space` walks up
from `$PWD` until it finds the nearest `space.yaml`. No "current space" state
to get out of sync; where you *are* is the space you mean. 🧭

## Installation 📦

Add it to your `Gemfile`:

```ruby
gem "space-cadet"
```

```bash
bundle install
```

Or grab it yourself:

```bash
gem install space-cadet
```

The gem is `space-cadet`; it installs one executable, `space`. 🎀

## Quick start 🎀

```sh
space init                                        # create XDG config + state files
space new "Name of Space"                         # blast off a new space 🚀
space new "Name of Space" -r org/repo -r org/lib  # …with repos cloned in (repeat -r)
space list                                        # see all your spaces
space show                                        # show the space you're standing in

# Containers (run from inside a space) — a portable, reproducible-by-SHA image of the space
space pack                                         # render build/oci/ (Dockerfile + entrypoint)
space build                                        # pack + build & tag <space-id>:<git-sha>
space run                                          # run it — login shell, auth from your env
```

## Commands 🌌

```sh
space init
space new "Name of Space"
space new "Name of Space" -r org/repo -r example-tools/alpha -r example-tools/beta
space list                                   # alias: space ls
space show 20260531-name-of-space
space path 20260531-name-of-space
space current                                # based on $PWD
space show                                   # based on $PWD
space status                                 # report: metadata (+ project status when present)
space status 20260531-name-of-space          # report another space
space status done                            # set: active | paused | done | archived
space status 20260531-name-of-space done
space config set default_provider github.com
space config set default_organization example-org
space repo add example-app                   # github.com/example-org/example-app
space repo add example-tools/alpha example-tools/beta
space repo add gitlab.com/example-org/api
space repo resolve example-app example-tools/async
space repo ls                                # alias: space repos ls
space use 20260531-name-of-space             # records recent state, prints the path
space ls --color=always                      # auto | always | never (--colors also accepted)
```

`space status` is **report-or-set**: with no status keyword (bare, or with just
a space id) it *reports* the space — its metadata plus a compact project-status
block when the space declares one, quietly omitted otherwise; pass a status
keyword (`active`, `paused`, `done`, `archived`) to *set* it instead. 🔁

Repos are passed with a repeatable `-r` flag (`-r org/repo -r org/lib`); the
comma form (`-r a,b`) works too. Space ids are date-prefixed
(`20260531-name-of-space`) so they sort naturally, and duplicate names on the
same day get a counter (`…-name-of-space-2`). 📅

Full command reference: [docs/reference.md](docs/reference.md).

## Containerize a space: `pack` · `build` · `run` 📦

A space is self-describing enough to become a container. `space pack` renders a
portable OCI build context from the space; `space build` packs and builds it into
a **reproducible-by-SHA** image; `space run` runs that image with your auth
injected at runtime and stateful paths bind-mounted back to the host. 🐳

```sh
space pack                    # render build/oci/ (Dockerfile + entrypoint + ignore file)
space pack -o /tmp/ctx        # …to a different output directory
space build                   # pack, then build & tag <space-id>:<git-sha> and :latest
space run                     # run <space-id>:latest — login shell, auth from your env
space run architect status    # …or run a one-off command instead of the login shell
space run --tty               # force an interactive TTY (default: auto-detect)
```

**What lands in the image.** The context copies the whole space tree (filtered by
a generated `Dockerfile.dockerignore`) onto a `ruby:4.0.5` base with `git`, the
Claude Code CLI, and the `space-cadet` gem — installed from the in-space
`repos/space-cadet` checkout when present (a pinned build), else from
RubyGems. Secrets never enter the layers: `.env`, `*.key`, `*.pem`, ssh keys,
`build/`, and `tmp/` are all excluded by the generated ignore file. 🔒

**Reproducible by SHA.** `space build` tags the image `<space-id>:<sha>`, where
`<sha>` is the space repo's 12-char `HEAD` (suffixed `-dirty` when the tree has
uncommitted changes), plus a moving `:latest`. Same commit → same tag → same
image. It drives the `container` CLI, but the output is an ordinary OCI/Docker
build context, so `docker build -f build/oci/Dockerfile .` (from the space root)
works just as well.

**Auth stays out of the layers.** `space run` injects only the auth environment
variables that are actually set — `ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`,
`ANTHROPIC_BASE_URL` — with `-e` at run time, so credentials live in your shell,
never in the image. 🗝️

**Forwarding payload credentials.** Beyond the always-on auth trio, a space can declare
`run.env:` in `space.yaml` — a list of host env var names forwarded into the container at
run time. You can also pass `space run --env VAR` (repeatable) for ad hoc additions. All
forwarding is bare `-e VAR` passthrough: values never appear in argv, `ps`, or the image.
A requested-but-unset var warns on stderr instead of silently failing inside the guest.

```yaml
run:
  env:                         # run-time: host var names, forwarded as bare -e VAR
    - FIREWORKS_API_KEY
    - OPENAI_API_KEY
```

**Declaring provisioning & persistence** — two optional keys in `space.yaml`:

```yaml
pack:
  provision:                 # build-time: relative scripts, baked in by `space build`
    - scripts/setup-toolchain.sh
  persist:                   # run-time: absolute guest paths, bind-mounted per run
    - /root/.claude
    - /root/.local/state
```

`provision` scripts must live under the space root and be executable. Each script is
copied into the image individually (`COPY <script> /space/<script>`) and then invoked
(`RUN /space/<script>`) **before** the full space tree lands and **before** the gem is
installed. This ordering is the cache-hygiene guarantee: editing any other space file
leaves the provision and gem-install layers cached, so a rebuild completes in seconds
instead of minutes. Scripts must therefore be self-contained — they run with only the
base system layers and any earlier provision scripts' outputs; they cannot read other
space files or call `space`. Scripts must have the executable bit set; COPY preserves
the mode from the build context.

`persist` paths must be absolute; `space run` bind-mounts each one from
`<space>/.state<path>` on the host (created on first run) so a container's mutable state
survives across runs. Both are validated at pack time.

## Fish shell integration 🐟

Shells can't let a child process change *their* working directory, so `space`
ships a small fish wrapper function plus completions (commands, subcommands,
spaces, statuses, config keys, repo refs). Install into fish's autoloaded
directories:

```fish
space shell fish install
exec fish
```

After restarting fish (or `exec fish`), `space new "…"` and
`space use <id>` will `cd` into the selected space once the command succeeds;
every other command keeps normal CLI behavior. 🚪 The functions and completions
are written under `~/.config/fish/`, so there's no need to edit `config.fish`.
For one-off testing without installing:

```fish
space shell init fish | source
```

## Configuration ⚙️

Config lives at `~/.config/space-cadet/config.yml` (XDG-aware) and defaults to:

```yaml
version: 1
base_dir: ~/architect            # spaces_dir + src_dir hang off this by default
default_provider: github.com
default_organization:
git_clone_protocol: ssh          # ssh | https
```

Derived defaults: `spaces_dir` → `<base_dir>/spaces`, `src_dir` (evergreen
checkout root) → `<base_dir>/src`. Override either explicitly. View values with
`space config show`; set one with `space config set KEY VALUE`. Editable keys:
`base_dir`, `spaces_dir`, `src_dir`, `default_provider`, `default_organization`,
`git_clone_protocol`.

## Repos: evergreen, copy-on-write, concurrent ⚡

Repos are added to the current space under `repos/` and tracked in `space.yaml`.
When an up-to-date evergreen checkout exists at
`<src_dir>/<host>/<owner>/<name>` (e.g.
`~/architect/src/github.com/example-org/example-app` — tended by
[jetpks/repo-tender](https://github.com/jetpks/repo-tender)), `space` copies it
into the space instead of cloning over the network — a copy-on-write clone on
APFS. ⚡ Set `src_dir` empty to always clone:

```sh
space config set src_dir ""
```

Clone URLs default to SSH (`git@github.com:example-org/example-app.git`); switch
with `space config set git_clone_protocol https`. Multiple repos passed to
`space repo add` are fetched **concurrently**, up to five at a time, on fibers —
no threads, all cooperative. 🧵 After each repo lands, `space` runs `mise trust`
in it. Each space also gets a workspace-local `tmp/` — use it instead of `/tmp`.

## Embedding 📚

```ruby
require "space_core"       # config, state, XDG, terminal, git/mise clients,
                           # the space store — the `space` CLI runs on this alone
```

## Documentation 📖

- **[Command Reference](docs/reference.md)** — every command, flag, and behavior
- **[Releasing](docs/RELEASING.md)** — how a release lands
- **[Changelog](CHANGELOG.md)** — release history

## Development 🛠️

```sh
bundle install
bundle exec rake test       # the minitest suite
bundle exec rake build      # build the gem into pkg/
bundle exec rake install    # build + install into your user gem home
```

## Contributing 💝

Bug reports and pull requests are welcome on GitHub at
[https://github.com/jetpks/space-cadet](https://github.com/jetpks/space-cadet)!

## License 📄

Available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

---

Made with 💖 and fibers 🧵 by Eric
