# How-to guides 🧭

Goal-oriented recipes — each one answers "how do I accomplish this task?"
with steps and no digression. If you're learning the tool for the first time,
start with the [tutorials](../tutorials/) instead; for look-it-up facts, see
the [reference](../reference/).

For users:

- **[Install, update, and migrate from 8.x](install-or-update.md)** — get the
  gem, keep it current, and let 9.x move your 8.x config/state across.
- **[Configure spaces and repos](configure-spaces-and-repos.md)** — set
  `base_dir`, `spaces_dir`, `src_dir`, providers, organizations, and the git
  clone protocol.
- **[Integrate with fish shell](fish-shell-integration.md)** — install the
  wrapper function and completions so `space new`/`space use` cd for you.
- **[Containerize a space](containerize-a-space.md)** — `pack`, `build`, and
  `run` a space as a reproducible OCI image.

For maintainers of this gem:

- **[Release a new version](release-a-new-version.md)** — the maintainer's
  release checklist (changelog, version bump, signed tag, automation).
