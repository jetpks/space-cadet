# Explanation 🤔

Understanding-oriented essays — the why behind the tool: design decisions,
trade-offs, history. No instructions here; for steps see
[how-to](../how-to/), for facts the [reference](../reference/).

- **[What is a space?](what-is-a-space.md)** — the model: a directory, an
  identity file, and `$PWD` as the only "current space" state.
- **[Why date-prefixed ids](date-prefixed-ids.md)** — self-describing roots
  that sort naturally, and the collision counter.
- **[Evergreen, copy-on-write provisioning](evergreen-cow-provisioning.md)** —
  why repos come from local checkouts at APFS clone speed, and how that
  relates to repo-tender.
- **[The 9.x split: from monolith back out](the-9x-split.md)** — how the
  space tool left the space-architect monolith, and what happens to your
  config and state.
