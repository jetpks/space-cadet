# CLI reference: `space` 🚀

Every `space` command, flag, and behavior. The gem installs one binary,
`space`, over the `Space::Core` seam. This page describes; it does not
teach — for a guided tour see the [tutorial](../tutorials/first-space.md),
for tasks the [how-to guides](../how-to/).

Derived from `space --help` at version 9.1.0.

## Global options 🎨

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `--color` | `auto` `always` `never` | `auto` | Color output. `--colors` is accepted too. |

Color defaults to auto-detection: colorized when stdout is a TTY, plain
otherwise. Paths under your home directory are displayed as `~/...` in
human-oriented output.

## Space resolution 🧭

Commands that take an optional `[IDENTIFIER]` resolve it in this order:

1. An explicit id or slug passed on the command line.
2. Otherwise, the nearest parent directory of `$PWD` containing a `space.yaml`.

Being *inside* a space is what makes it current — `space use` records recent
state and prints a path, but it never overrides `$PWD`-based resolution.

## Commands 🗂️

### `space init`

```text
Usage: space init
  Create default XDG config and state files
  --[no-]force    Overwrite existing config and state files (default: false)
```

Prints the config, state, and spaces-dir paths it ensured. `--force` rewrites
both files with defaults.

### `space new TITLE`

```text
Usage: space new TITLE
  Create a new project space
  -r, --repo=REPO   Repo ref to clone (repeatable: pass -r once per repo;
                    the comma form `-r a,b` also works)
  --[no-]git        Initialize the space as a Git repository (default)
```

The id is date-prefixed and slugged from the title (`"Name of Space"` →
`20260531-name-of-space`); duplicate names on the same day get a counter
(`…-name-of-space-2`). Repos are provisioned into `repos/` immediately —
copy-on-write from an evergreen checkout when available, else cloned.

Examples from `--help`:

```sh
space new "My Space" -r org/repo -r example-tools/alpha   # clone two repos into the space
```

### `space list` (alias `space ls`)

```text
Usage: space list
  List spaces
```

Compact table of id, status, date, title, path. Honors `--color`.

### `space show [IDENTIFIER]`

```text
Usage: space show [IDENTIFIER]
  Show metadata for a space or the current space
```

Prints ID, Title, Status, Path, Created, Updated. Fails with `Could not find
space matching '…'` when the identifier matches nothing.

### `space path [IDENTIFIER]`

```text
Usage: space path [IDENTIFIER]
  Print the path for a space or the current space
```

Prints *only* the path — handy for scripting (`cd "$(space path)"`).

### `space use IDENTIFIER`

```text
Usage: space use IDENTIFIER
  Remember a space in recent state and print its path
```

Records the space in recent state (the `Recent space:` line in listings) and
prints its path.

### `space current`

```text
Usage: space current
  Show the current space
```

Resolved from `$PWD` by walking up to the nearest `space.yaml`; errors with
`No current space found from <dir> …` when run outside any space.

### `space status [SPACE] [STATUS]`

```text
Usage: space status [REST]        # REST = [SPACE] STATUS
  Set a space status: active, paused, done, archived
```

**Report or set.** With no status keyword — bare, or with just a space id —
it *reports* the space: its metadata (ID, Title, Status, Path, Created,
Updated) plus a compact project-status block when the space declares one,
quietly omitted otherwise. Pass a status keyword to *set* it instead;
supported statuses: `active`, `paused`, `done`, `archived`. The bare word
`space status help` prints the command help instead of reporting or setting.

```sh
space status                                   # report the current space
space status 20260531-name-of-space            # report another space
space status done                              # set the current space's status
space status 20260531-name-of-space archived   # set another space's status
```

(Note: the command's `--help` description string says only "Set a space
status"; the report form above is the observed behavior.)

### `space config [SUBCOMMAND]`

Show or update configuration. Full key reference:
[Configuration](configuration.md).

```text
Usage: space config path     # Print the config file path
Usage: space config set KEY VALUE   # Set a config key
Usage: space config show     # Show current config
```

- **`space config show`** — every key and its current value; unset optional
  keys (`spaces_dir`, `src_dir`, `default_organization`) render blank.
- **`space config path`** — the config file path.
- **`space config set KEY VALUE`** — set one of the six editable keys
  (`base_dir`, `spaces_dir`, `src_dir`, `default_provider`,
  `default_organization`, `git_clone_protocol`); an unknown key fails with
  the accepted list.

### `space repo [SUBCOMMAND]` (alias namespace `space repos`)

Manage repos in the current space. `space repos …` dispatches identically to
`space repo …`, including the `list`/`ls` alias pair.

```text
Usage: space repo add [REPOS]      # Add repos to the current space (copy-on-write from an evergreen checkout when available, else clone)
Usage: space repo list             # List repos in the current space (alias: space repo ls)
Usage: space repo resolve [REPOS]  # Resolve repo refs without cloning
```

- **`space repo add REPO [REPO…]`** — add repos into `repos/` and track them
  in `space.yaml`; multiple repos are fetched concurrently, up to five at a
  time. After each repo lands, `mise trust` runs in it.
- **`space repo list`** — table of full name and in-space path; prints `No
  repos found in <id>` for an empty space.
- **`space repo resolve REPO [REPO…]`** — print the resolved full name and
  clone URL without cloning.

### `space shell [SUBCOMMAND]`

Manage shell integration. Only `fish` is supported today.

```text
Usage: space shell init SHELL_NAME   # Print shell integration script
Usage: space shell fish [SUBCOMMAND] # Manage fish shell integration: install, uninstall, path
Usage: space shell complete KIND [EXTRA]  # Print completion candidates
```

- **`space shell init fish`** — print the fish wrapper function to stdout
  (`space shell init fish | source` to try it without installing).
- **`space shell fish`** — default subcommand is `install`. Options and
  subcommands:
  - `space shell fish install` — write the function to
    `~/.config/fish/functions/space.fish` and completions to
    `~/.config/fish/completions/space.fish` (XDG-aware); `--force` overwrites
    existing files. Prints a reminder to `exec fish`.
  - `space shell fish uninstall` — remove both files (`--force` to remove
    without prompting).
  - `space shell fish path` — print both install paths.
- **`space shell complete KIND [EXTRA]`** — print completion candidates for
  the given kind (used by the fish completions themselves).

### `space pack`

```text
Usage: space pack
  Generate a portable OCI build context for the current space
  -o, --output=DIR   Output directory (default: build/oci/ under the space root)
```

Renders a `Dockerfile`, an executable `entrypoint.sh`, and a
`Dockerfile.dockerignore` into the output directory. Writes the context only —
no image is built. The Dockerfile is rendered in cache-hygiene layer order:
stable system layers, then each `pack.provision` script copied and run
individually, then the gem install, then the full space tree. The gem is
installed from the in-space `repos/space-cadet` checkout when present
(determined at render time), else from RubyGems. Reads and validates the
`pack.provision` / `pack.persist` keys from `space.yaml` (see
[`space.yaml` reference](space-yaml.md)).

### `space build`

```text
Usage: space build
  Build (and tag) the OCI image for the current space
```

Packs, then builds and tags the image via the `container` CLI. Two tags:
`<space-id>:<sha>` (the space repo's 12-char `HEAD`, suffixed `-dirty` when
the working tree has uncommitted changes) and `<space-id>:latest`. Same
commit ⇒ same tag ⇒ same image. Requires the space to be a Git repository
with at least one commit. The generated context is a standard OCI/Docker
build context, so `docker build -f build/oci/Dockerfile .` from the space
root works with any OCI builder.

### `space run [COMMAND]`

```text
Usage: space run [COMMAND]
  Run the packed OCI image for the current space (auth injected at runtime).
  Pass a command and its arguments after `--` so they forward as separate argv tokens
  --[no-]tty    Force interactive TTY (default: auto-detect)
  --env=VAR     Host env var to forward into the container (repeatable; adds to run.env)
```

Runs `<space-id>:latest` via `container run --rm`. With no `COMMAND` it
starts a login shell; pass one to run it once instead:

```sh
space run                         # login shell
space run -- hermes -z 'hello'    # one-off command
space run --tty                   # force an interactive TTY
space run --env FIREWORKS_API_KEY -- hermes -z 'hello'
```

`--` keeps the payload's flags from the CLI parser (a quoted multi-word
command without `--` arrives as one token and fails in-guest). Only auth
variables that are actually set are forwarded as bare `-e VAR` —
`ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_BASE_URL` — so
credentials are never baked into the image. `pack.persist` paths are
bind-mounted from `<space>/.state<path>` (created before the run). Declared
vars overlapping the auth trio are deduplicated; a requested-but-unset var
warns on stderr and the run continues. Full contract:
[`space.yaml` reference](space-yaml.md).

### `space version` (and `space --version`)

```sh
space version
```

Prints the version (for example `9.1.0`). Handled before command dispatch and
side-effect-free — note that it does not appear in `space --help`'s command
list, which is generated from the registered command set.

## Exit codes 🚦

`space` exits `0` on success. Failures — unknown space, ambiguous id, missing
required arguments, refusing to overwrite an existing file without `--force`,
invalid config values — exit non-zero with a clear message on stderr. Running
with an unregistered command word prints the top-level help and exits `1`. An
interrupted run exits `130`.
