# Containerize a space 🐳

How to turn a space into a container image, run it with your auth injected at
run time, and keep container state across runs — using `space pack`, `space
build`, and `space run`. A space is self-describing enough to become a
portable, reproducible-by-SHA image of the whole workspace.

## Pack: render the build context

From inside a space:

```sh
space pack
```

Renders a portable OCI build context into `build/oci/` — a `Dockerfile`, an
executable `entrypoint.sh`, and a `Dockerfile.dockerignore`. Write it
somewhere else with:

```sh
space pack -o /tmp/space-ctx
```

The context copies the whole space tree (filtered by the generated ignore
file) onto a `ruby:4.0.5` base with `git`, the Claude Code CLI, and the
`space-cadet` gem — installed from the in-space `repos/space-cadet` checkout
when present (a pinned build), else from RubyGems.

**Secrets never enter the layers.** The generated ignore file excludes `.env`,
`*.key`, `*.pem`, ssh keys, `build/`, and `tmp/`.

## Build: pack and tag

```sh
space build
```

Packs, then builds and tags the image via the `container` CLI with two tags:
`<space-id>:<sha>` — `<sha>` is the space repo's 12-char `HEAD`, suffixed
`-dirty` when the working tree has uncommitted changes — plus a moving
`<space-id>:latest`. Same commit ⇒ same tag ⇒ same image. Requires the space
to be a Git repository with at least one commit.

The context is a standard OCI/Docker build context, so any OCI builder works:

```sh
docker build -f build/oci/Dockerfile .    # from the space root
```

**Cache hygiene comes from layer order.** The Dockerfile runs stable system
layers first, then each `pack.provision` script copied and run individually,
then the gem install, then the full space tree (`COPY . /space`). After a cold
build, editing space content re-runs only `COPY . /space` and later —
provision and gem-install layers stay cached, so a rebuild takes seconds. The
price: provision scripts must be self-contained (see below).

## Run: auth injected, state persisted

```sh
space run                      # login shell in <space-id>:latest
space run --tty                # force an interactive TTY (default: auto-detect)
space run -- hermes -z 'hi'    # one-off command; `--` forwards args as separate tokens
```

The image runs via `container run --rm`. Only the auth environment variables
that are actually set on your host are forwarded, as bare `-e VAR` at run
time — `ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_BASE_URL` —
so credentials live in your shell, never in the image or in `ps`.

## Declare provisioning, persistence, and env in `space.yaml`

Two optional `pack:` keys and one `run:` key, read by `pack`/`build`/`run`:

```yaml
pack:
  provision:                 # build-time scripts, baked into the image
    - scripts/setup-toolchain.sh
  persist:                   # run-time guest paths, bind-mounted per run
    - /root/.claude
run:
  env:                       # host var names forwarded at run time
    - FIREWORKS_API_KEY
    - OPENAI_API_KEY
```

**`provision`** — space-root-relative, executable scripts. Each is copied into
the image individually (`COPY <script> /space/<script>` + `RUN
/space/<script>`) before the space tree lands and before the gem install. A
script sees only the base system layers plus earlier scripts' outputs — it
cannot read other space files or call `space`. The cache-hygiene layer order
is why.

**`persist`** — absolute guest paths. `space run` bind-mounts each from
`<space>/.state<path>` on the host (created on first run) so container state
survives across runs.

**`run.env`** — host env var *names only*; values are never written to
`space.yaml` or baked into the image. At run time each is forwarded as bare
`-e VAR`; a requested-but-unset var warns on stderr and the run continues. Add
ad hoc vars per run with the repeatable `--env VAR` flag:

```sh
space run --env FIREWORKS_API_KEY -- hermes -z 'hello'
```

Invalid `pack.provision`/`pack.persist` entries (a missing or non-executable
script, a path escaping the space root, a relative persist path) fail the
command at pack time, before anything is written.

For the full key-by-key contract, see
[`space.yaml` reference](../reference/space-yaml.md).
