# Integrate with fish shell 🐟

How to install the `space` fish integration so that creating and switching
spaces changes your working directory for you, and get completions for
commands, subcommands, spaces, statuses, config keys, and repo refs.

> Shells can't let a child process change *their* working directory, so `space`
> can't `cd` on its own — the integration is a small fish wrapper function that
> calls `space` and then cds when the command succeeded.

## Install

```fish
space shell fish install
exec fish
```

The function and completions are written under `~/.config/fish/` (XDG-aware):

- `~/.config/fish/functions/space.fish`
- `~/.config/fish/completions/space.fish`

There's no need to edit `config.fish` — fish autoloads both. `exec fish`
restarts fish so the new files load in the current terminal.

After that, `space new "…"` and `space use <id>` `cd` into the space once the
command succeeds; every other command keeps normal CLI behavior.

## Inspect or force-reinstall

```fish
space shell fish path            # print both install paths
space shell fish install --force # overwrite existing files
```

Without `--force`, install refuses to overwrite an existing file that `space`
did not write ("Refusing to overwrite existing … Re-run with --force"); files
it manages or that already match are left as-is ("unchanged").

## Uninstall

```fish
space shell fish uninstall
```

Removes both files. As with install, a pre-existing file that `space` didn't
write is only removed with `--force`.

## Try it without installing

```fish
space shell init fish | source
```

Prints the wrapper function to stdout and loads it into the current shell —
handy for a one-off test. Completions are not loaded this way; `install` is
required for those.

## Other shells

Only fish is supported today. `space shell init SHELL_NAME` rejects anything
else.
