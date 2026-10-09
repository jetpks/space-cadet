# Command Reference 📖

Every `space-cadet` command, flag, and behavior. The gem installs one first-class binary — `space` — over the `Space::Core` seam. 🚀

## Global options 🎨

These work on any command:

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `--color` | `auto` `always` `never` | `auto` | Color output. `--colors` is accepted too. |

Color defaults to auto-detection: colorized when stdout is a TTY, plain otherwise. Paths under your home directory are displayed as `~/...` in human-oriented output.

## Space resolution 🧭

Commands that take an optional `[SPACE]` resolve it in this order:

1. An explicit id or slug passed on the command line.
2. Otherwise, the nearest parent directory of `$PWD` containing a `space.yaml`.

Being *inside* a space is what makes it current — `space use` records recent state and prints a path, but it never overrides `$PWD`-based resolution.

## Space commands 🗂️

### `space init`

Create the default XDG config and state files.

```sh
space init
```

### `space new TITLE [-r REPO]...`

Create a new space. The id is date-prefixed and slugged from the title (`"Name of Space"` → `20260531-name-of-space`); duplicate names on the same day get a counter (`...-name-of-space-2`). Repos are passed with a repeatable `-r` flag (the comma form `-r a,b` works too) and are cloned into the new space immediately.

```sh
space new "Name of Space"
space new "Name of Space" -r example-tools/alpha -r example-tools/beta
space new "Name of Space" --no-git   # skip git init
```

| Option | Description |
|--------|-------------|
| `-r, --repo=REPO` | Repo ref to clone; repeat once per repo (comma form also accepted). |
| `--[no-]git` | Initialize the space as a Git repository (default: `--git`). |

### `space list` (alias `space ls`)

List all spaces, compact and human-readable.

```sh
space list
space ls --color=always
```

### `space show [IDENTIFIER]`

Show metadata for a space, or the current space when no id is given.

```sh
space show
space show 20260531-name-of-space
```

### `space path [IDENTIFIER]`

Print *only* the path for a space (handy for scripting).

```sh
space path
space path 20260531-name-of-space
```

### `space use IDENTIFIER`

Record a space in recent state and print its path.

```sh
space use 20260531-name-of-space
```

### `space current`

Show the current space, resolved from `$PWD`.

```sh
space current
```

### `space status [SPACE] [STATUS]`

**Report or set.** With no status keyword — bare, or with just a space id — it *reports* the space: its metadata (ID, Title, Status, Path, Created, Updated) followed by a compact project-status block when the space declares one, quietly omitted otherwise. Pass a status keyword to *set* it instead; supported statuses: `active`, `paused`, `done`, `archived`.

```sh
space status                                   # report the current space
space status 20260531-name-of-space            # report another space
space status done                              # set the current space's status
space status 20260531-name-of-space archived   # set another space's status
```

### `space config [SUBCOMMAND]`

Show or update configuration.

```sh
space config show
space config path
space config set default_provider github.com
space config set default_organization example-org
space config set git_clone_protocol https
space config set src_dir ""                    # disable evergreen copy-on-write (always clone)
```

Config lives at `~/.config/space-cadet/config.yml` (XDG-aware):

```yaml
version: 1
base_dir: ~/architect            # spaces_dir + src_dir hang off this by default
default_provider: github.com
default_organization:
git_clone_protocol: ssh          # ssh | https
```

`spaces_dir` defaults to `<base_dir>/spaces` and `src_dir` (the evergreen checkout root) to `<base_dir>/src`; set either explicitly to override. Editable keys: `base_dir`, `spaces_dir`, `src_dir`, `default_provider`, `default_organization`, `git_clone_protocol`.

### `space repo [SUBCOMMAND]` (alias `space repos`)

Manage repos in the current space.

```sh
space repo add example-app
space repo add example-tools/alpha example-tools/beta
space repo add gitlab.com/example-org/api
space repo list            # alias: ls
space repo resolve example-app example-tools/async
```

- **add** — add repos into `repos/` (copy-on-write from an evergreen checkout under `src_dir` when available, else clone), concurrently up to five at a time.
- **list** / **ls** — list repos tracked in the current space.
- **resolve** — print the resolved full name and clone URL without cloning.

### `space shell [SUBCOMMAND]`

Manage shell integration. Only `fish` is supported today.

```sh
space shell init fish              # print the fish function to stdout
space shell fish install           # install function + completions
space shell fish install --force   # overwrite existing files
space shell fish uninstall
space shell fish path              # print install paths
space shell complete spaces        # print completion candidates
```

### `space pack`

Render a portable OCI build context for the current space into `build/oci/` (override with `-o`): a `Dockerfile`, an executable `entrypoint.sh`, and a `Dockerfile.dockerignore`. The Dockerfile is rendered in cache-hygiene layer order: stable system layers first, then each `pack.provision` script copied and run individually, then the gem install, then the full space tree. This means a space-content edit after a cold build leaves the provision and gem-install layers cached — only `COPY . /space` and later re-run, so the rebuild completes in seconds. The gem is installed from the in-space `repos/space-cadet` checkout when present (determined at render time), else from RubyGems; the generated ignore file keeps secrets and scratch (`.env`, `*.key`, `*.pem`, ssh keys, `build/`, `tmp/`) out of the layers. Reads and validates the `pack.provision` / `pack.persist` keys from `space.yaml` (see below). Writes the context only — no image is built.

```sh
space pack
space pack -o /tmp/space-ctx
```

| Option | Description |
|--------|-------------|
| `-o, --output=DIR` | Output directory for the build context (default: `build/oci/` under the space root). |

### `space build`

Pack, then build **and tag** the image via the `container` CLI. Two tags are applied: `<space-id>:<sha>` — where `<sha>` is the space repo's 12-char `HEAD`, suffixed `-dirty` when the working tree has uncommitted changes — and a moving `<space-id>:latest`. Same commit ⇒ same tag ⇒ same image (reproducible by SHA). Requires the space to be a Git repository with at least one commit. The generated context is a standard OCI/Docker build context, so `docker build -f build/oci/Dockerfile .` from the space root builds the same image with any OCI builder.

```sh
space build
```

### `space run [COMMAND]`

Run `<space-id>:latest` via `container run --rm`, injecting auth and mounting persisted state. With no `COMMAND` it starts a login shell; pass a command to run it once instead. Only the auth environment variables that are actually set are forwarded with bare `-e VAR` — `ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_BASE_URL` — so credentials are never baked into the image. Each `pack.persist` path is bind-mounted from `<space>/.state<path>` on the host (created before the run) so container state survives across runs.

Vars declared under `run.env:` in `space.yaml` and vars passed via `--env` are also forwarded as bare `-e VAR` passthrough — values never appear in argv, `ps`, or the image. Declared vars that overlap the always-on auth trio are deduplicated to a single `-e`. A requested-but-unset var emits a stderr warning and is omitted from argv (it does not fail the run).

```sh
space run                         # login shell
space run -- hermes -z 'hello'    # one-off command
space run --tty                   # force an interactive TTY
space run --env FIREWORKS_API_KEY -- hermes -z 'hello' # ad hoc env forward; -- keeps the payload's flags from the CLI parser
```

| Option | Description |
|--------|-------------|
| `--[no-]tty` | Force (or disable) an interactive TTY. Default: auto-detected from the output stream. |
| `--env VAR` | Forward a host env var into the container as bare `-e VAR` (repeatable; adds to `run.env:`). |

### Declaring provisioning, persistence & runtime env (`space.yaml`)

The `pack`-family commands and `space run` read optional keys from `space.yaml`:

```yaml
pack:
  provision:                 # build-time scripts, each COPY'd and RUN before the space tree lands
    - scripts/setup-toolchain.sh
  persist:                   # absolute guest paths, bind-mounted from <space>/.state<path> at run
    - /root/.claude
run:
  env:                       # host var names forwarded as bare -e VAR at run time (values never baked)
    - FIREWORKS_API_KEY
```

**`provision` contract.** Entries must be space-root-relative paths that exist under the space and must be executable (COPY preserves the bit from the build context). Each script is copied into the image individually — `COPY <script> /space/<script>` immediately followed by `RUN /space/<script>` — so its cache key is the script's own content: editing any other space file leaves its layer cached. Scripts run **before** the full space tree is copied and **before** the gem is installed, in declared order. A script therefore sees only the base system layers plus outputs of any earlier scripts; it must be self-contained (network + its own file only) and cannot read other space files or call `space`. The payoff: after the first (cold) build, a space-content edit triggers only `COPY . /space` and later — provision and gem-install layers stay cached and the rebuild completes in seconds.

`persist` entries must be absolute. Both `provision` and `persist` are validated at pack time — an absolute or missing provision path, a provision path that escapes the space root, or a relative persist path fails the command before anything is written.

**`run.env` contract.** Entries are host env var **names only** — values are never written to `space.yaml` or baked into the image. At `space run` time, each named var is read from the host and forwarded as bare `-e VAR` (no `=value` in argv). A var that is unset or empty on the host is omitted from argv and a stderr warning names it — the run continues so you can diagnose which credential is missing. Vars that overlap the always-on auth trio are deduplicated. Ad hoc additions use `space run --env VAR` (repeatable).

## Exit codes 🚦

`space` exits non-zero on failure — unknown space, ambiguous id, refusing to overwrite an existing file without `--force`, and so on — with a clear message on stderr.
