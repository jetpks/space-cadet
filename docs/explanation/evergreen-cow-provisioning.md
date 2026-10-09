# Evergreen, copy-on-write provisioning ⚡

When a space needs a repo, `space` prefers a local copy over the network:
if an up-to-date *evergreen checkout* exists under `src_dir`
(`<base_dir>/src`, e.g. `~/architect/src/github.com/example-org/example-app`),
the repo is copied into the space as an APFS **copy-on-write clone** — near
instant, no bytes over the wire. Only when no checkout exists does `space`
fall back to a real `git clone`.

This page explains why. For the knobs (`src_dir`, `git_clone_protocol`,
`default_provider`), see [Configure spaces and repos](../how-to/configure-spaces-and-repos.md).

## Why evergreen checkouts

Two failure modes plague "clone per task" workflows: network latency on every
`space new` (worse with several repos), and stale-clone drift (every space
cloned last month is a month behind). An evergreen checkout solves both at
once: one canonical, continuously-updated copy of each repo per machine.
`tend` it with [repo-tender](https://github.com/jetpks/repo-tender) (or your
own `git fetch` cron); spaces then provision from local disk in a heartbeat
and start from fresh-enough history.

The design accepts a trade: a space's repo is a *copy from a moment in
time*, not a live checkout. That's the point — a space is a task-scoped
snapshot. Refreshing is one command away (`space repo add` from a tended
checkout again, or plain `git pull` inside the space's clone).

## Why copy-on-write

APFS `clonefile` gives a full, independent-looking working tree that costs
almost no disk until one side writes. The space's copy behaves like a real
clone — its own `.git`, its own branches, its own uncommitted mess — while
sharing untouched blocks with the evergreen checkout. Ten spaces can hold ten
copies of a monorepo for the price of roughly one. The checkout must live on
the same APFS volume as the spaces; otherwise the copy degrades to a plain
recursive copy, which is slower but still correct.

## Concurrency on fibers

Multiple repos passed to one command (`space repo add a b c …`) are fetched
**concurrently, up to five at a time** (`MAX_CONCURRENT_CLONES = 5`),
implemented on fibers over the async scheduler — cooperative concurrency, no
threads. Cloning is I/O-bound, so fibers are exactly the right weight; five
is the point where added parallelism stops paying for itself on typical
networks. After each repo lands, `mise trust` runs in it so tool
configurations are trusted without a second pass.

## How it relates to repo-tender

The evergreen checkout is a *convention* (a directory layout under `src_dir`);
repo-tender is the tool that maintains it — keeping checkouts clean, on the
default branch, and fresh. The dependency is soft: `space` provisions fine
from any directory tree that happens to match the layout, and falls back to
cloning when `src_dir` is empty or the checkout is missing. The two gems
share no code path beyond the filesystem convention.
