# What is a space? 🪐

A space is just a regular directory with a tiny YAML identity file and room
for everything one task needs. That's the whole trick — and the design
follows from taking it seriously.

## The shape

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

Nothing exotic: no database, no daemon, no hidden state. A space is
human-browsable, `grep`-able, `rm -rf`-able, and trivially backed up. The
identity file (`space.yaml`) is small and complete enough that a directory
*is* the record of the task.

## Why `$PWD` is the "current space"

Tools with a notion of "the active project" usually keep it in state — an
environment variable, a cursor file, a workspace setting. That state drifts
from reality: you `cd` and suddenly the tool means a different thing than you
do.

`space` inverts this: commands resolve their target by walking up from the
current directory until they find `space.yaml`. Where you *are* is the space
you mean. There is no stored "current space" to get out of sync, no `space
switch` ritual, and two terminals can sit in two spaces without confusing
each other. `space use` exists to *record* a space in recent state (which
enriches `space list`), never to override resolution.

The same property makes spaces composable with other tooling: anything that
can `cd` can enter a space, and anything inside the space can ask `space`
where it is (`space path`).

## Spaces alongside the other two gems

`space-cadet` is the substrate. The
[Architect Loop](https://github.com/jetpks/space-architect) runs *inside* a
space (that's what `architecture/` is for), and
[repo-tender](https://github.com/jetpks/repo-tender) keeps the evergreen
checkouts that space provisioning prefers — see
[Evergreen, copy-on-write provisioning](evergreen-cow-provisioning.md).

## Why there's a workspace-local `tmp/`

Scratch space is where discipline goes to die: files accumulate in `/tmp`
with no relation to the task that made them. Each space gets its own `tmp/`
so temp artifacts travel with the task, get cleaned with it, and never leak
across spaces.
