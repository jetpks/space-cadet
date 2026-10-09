# Your first space 🪐

This tutorial walks you through one complete journey: install the gem, create
a workspace (a *space*), provision a repository into it, and check its status.
By the end you'll have a self-describing directory that holds everything one
task needs — and you'll know the four commands that matter most.

Everything here works on a fresh machine with only the gem installed.

> If you'd rather browse facts than follow steps, the
> [command reference](../reference/cli.md) lists every command. This page is
> the guided tour.

## What you'll build 🏗️

A space at `~/architect/spaces/20261009-my-first-space` containing:

```text
20261009-my-first-space/
  space.yaml        # identity: id, title, status, repos, notes, tags
  README.md
  repos/            # provisioned repositories
  notes/            # scratch, prompts, logs
  architecture/     # project files, when a project uses the space
  build/            # OCI contexts + scratch
  tmp/              # workspace-local temp — use this instead of /tmp
```

## 0. Install 📦

```sh
gem install space-cadet
```

This installs one executable, `space`. Check it:

```sh
space version
```

You'll see the gem version printed (for example `9.1.0`). If you're upgrading
from the space-architect 8.x monolith instead, see
[Install, update, and migrate from 8.x](../how-to/install-or-update.md) — your
config and state migrate automatically.

## 1. Initialize config and state ⚙️

```sh
space init
```

You'll see three paths printed:

```text
Config: ~/.config/space-cadet/config.yml
State: ~/.local/state/space-cadet/state.yml
Spaces: ~/architect/spaces
```

That's the default XDG layout: one config file, one state file, and a
`~/architect/spaces` root where all your spaces will live. Nothing else to
set up.

## 2. Create a space 🚀

```sh
space new "My First Space"
```

```text
Created 20261009-my-first-space
~/architect/spaces/20261009-my-first-space
```

The id is **date-prefixed** (`20261009-…`) so spaces sort chronologically in
listings. The title you gave is stored inside `space.yaml`.

> Want repos cloned in at creation time? `space new "My First Space" -r
> org/repo` accepts a repeatable `-r` flag. We'll add a repo in step 4
> instead, so you see both moves.

## 3. Go inside and report 🔎

```sh
cd ~/architect/spaces/20261009-my-first-space
space status
```

```text
ID:         20261009-my-first-space
Title:      My First Space
Status:     active
Path:       ~/architect/spaces/20261009-my-first-space
Created:    2026-10-09T10:47:55-06:00
Updated:    2026-10-09T10:47:55-06:00
```

Notice you didn't pass an id — `space` walks up from your current directory
until it finds `space.yaml`, so *where you are* is the space you mean. Run it
from anywhere inside the space and it just works; there's no "current space"
state to get out of sync.

A space's status is one of `active`, `paused`, `done`, `archived`. Set it by
passing the keyword:

```sh
space status paused
```

```text
20261009-my-first-space is paused
```

The same command *reports* when you omit the keyword and *sets* when you pass
one.

## 4. Provision a repo into the space ⚡

Add a repository to work on (this clones over the network the first time):

```sh
space repo add jetpks/space-cadet
```

```text
Added github.com/jetpks/space-cadet
~/architect/spaces/20261009-my-first-space/repos/space-cadet
```

The repo lands under `repos/` and is tracked in `space.yaml`. If you have an
evergreen checkout of that repo under your `src_dir`
(`~/architect/src/github.com/jetpks/space-cadet` — tended by
[jetpks/repo-tender](https://github.com/jetpks/repo-tender)), no network is
used at all: `space` copies it into the space as an APFS copy-on-write clone,
which is near-instant. See
[Evergreen, copy-on-write provisioning](../explanation/evergreen-cow-provisioning.md)
for why.

Multiple repos at once are fetched concurrently, up to five at a time:

```sh
space repo add jetpks/space-cadet jetpks/repo-tender
```

Confirm what the space tracks:

```sh
space repo list
```

```text
Repo                                 Path
github.com/jetpks/space-cadet        repos/space-cadet
```

## 5. Wrap up the task ✅

When the work is finished, mark the space done and step away:

```sh
space status done
space use 20261009-my-first-space    # optional: record it in recent state
```

The space stays on disk exactly as you left it — that's the point. Reopen it
any time by `cd`-ing back in.

## Where to next 🧭

- **Recipes for real tasks:** the [how-to guides](../how-to/) — configure
  `base_dir`/`src_dir`, fish shell integration, containerizing a space with
  `pack`/`build`/`run`.
- **Every command and flag:** the [reference](../reference/).
- **Why spaces work this way:** [explanation](../explanation/) — what a space
  is, why ids are date-prefixed, why provisioning is copy-on-write.
