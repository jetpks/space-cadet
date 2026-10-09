# Why date-prefixed ids 📅

Space ids look like `20260531-name-of-space`. Three decisions are packed into
that format, and each one trades a little verbosity for a lot of
self-evidence.

## 1. The directory describes itself

A space root's name tells you *what and when* without opening anything. In a
directory listing, a shell history grep, or a screenshot, `20260531-auth-refactor`
answers the two questions you always have — which task, from when — before
any tool runs. The title lives in the id, and `space.yaml` holds the fully
human form; the slug is a lossy-but-sufficient echo.

## 2. Chronological order is filesystem order

Date prefixing makes `ls` a timeline. `space list`, tab completion, and plain
`ls ~/architect/spaces` all sort the same way: oldest work first, current
work at the bottom. No separate index to consult or keep fresh.

## 3. Names are unique by construction — with a humane escape

Two spaces named the same thing on the same day are not an error you must
resolves by renaming: the second gets a counter
(`…-name-of-space-2`). Across days, the date itself disambiguates, so a
recurring task can have a fresh space each time without collision.

## The trade

Ids are longer than bare titles, and they bake the creation date in — a
space worked on for months carries its birthday in its name. That's
deliberate: spaces are task-scoped, not evergreen. A task has a beginning
(the date) and an end (`space status done`); the id records the beginning
while the status records the end. Renaming by hand is possible but pointless —
the id is what the tool knows, and a space that outgrows its name is usually
a signal to open a new one and reference the old.
