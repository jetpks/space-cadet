# `space.yaml` reference 🪪

Every space's identity file. Lives at the space root; `space` walks up from
`$PWD` to find it. This page lists the keys the tool writes and reads — for
what a space *is*, see [What is a space?](../explanation/what-is-a-space.md).

## Example

```yaml
---
version: 2
id: 20261009-yaml-look
title: Yaml Look
status: active
created_at: '2026-10-09T10:49:02-06:00'
updated_at: '2026-10-09T10:49:02-06:00'
repos: []
notes: []
tickets: []
tags: []
```

## Keys

| Key | Written by | Meaning |
|---|---|---|
| `version` | `space new` | File format version (currently `2`). |
| `id` | `space new` | Date-prefixed slug: `YYYYMMDD-<title-slug>`; same-day duplicates get a counter (`…-2`). |
| `title` | `space new` | The human title you passed to `space new TITLE`. |
| `status` | `space status <keyword>` | One of `active`, `paused`, `done`, `archived`; starts `active`. |
| `created_at` / `updated_at` | the tool | ISO-8601 timestamps, maintained automatically. |
| `repos` | `space repo add` | Tracked repos — full name plus in-space path under `repos/`. |
| `notes` | `space new` | Reserved for note entries. |
| `tickets` | `space new` | Reserved for ticket references. |
| `tags` | `space new` | Space tags. |

A space may also declare a project-status block; `space status` (report form)
renders it when present and omits it quietly otherwise.

## Pack/run keys (optional)

Three optional keys extend a space for containerization. They are read by
`space pack` / `space build` / `space run` and validated at pack time.

```yaml
pack:
  provision:                 # build-time scripts, baked into the image by `space build`
    - scripts/setup-toolchain.sh
  persist:                   # run-time: absolute guest paths, bind-mounted per run
    - /root/.claude
run:
  env:                       # host var names forwarded as bare -e VAR at run time
    - FIREWORKS_API_KEY
```

### `pack.provision`

- Entries are **space-root-relative** paths that must exist under the space
  and have the executable bit set (COPY preserves the mode from the build
  context).
- Each script is copied into the image individually — `COPY <script>
  /space/<script>` immediately followed by `RUN /space/<script>` — so its
  cache key is the script's own content: editing any other space file leaves
  its layer cached.
- Scripts run **before** the full space tree is copied and **before** the gem
  is installed, in declared order. A script therefore sees only the base
  system layers plus outputs of earlier scripts; it must be self-contained
  (network + its own file only) and cannot read other space files or call
  `space`.

### `pack.persist`

- Entries are **absolute** guest paths. At `space run` time each is
  bind-mounted from `<space>/.state<path>` on the host (created on first
  run), so container state survives across runs.

### Validation

`pack` validates both lists before writing anything: a missing or non-
executable provision script, a provision path escaping the space root, or a
relative persist path fails the command.

### `run.env`

- Entries are host env var **names only** — values are never written to
  `space.yaml` or baked into the image.
- At `space run` time each named var is read from the host and forwarded as
  bare `-e VAR` (no `=value` in argv, so values never appear in `ps` or the
  image).
- A var that is unset or empty on the host is omitted from argv with a stderr
  warning naming it; the run continues.
- Vars overlapping the always-on auth trio (`ANTHROPIC_API_KEY`,
  `CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_BASE_URL`) are deduplicated to a
  single `-e`. Ad hoc additions: `space run --env VAR` (repeatable).
