# Configure spaces and repos ⚙️

How to point `space` at the directories and git remotes you actually use:
where spaces live, where evergreen checkouts live, which forge and
organization repo refs default to, and how repos are cloned.

All commands below edit `~/.config/space-cadet/config.yml` (XDG-aware) — see
[Configuration reference](../reference/configuration.md) for the full key
list, defaults, and file paths.

## Change where spaces live

```sh
space config set base_dir ~/work
```

Spaces land under `<base_dir>/spaces`. To move the spaces root off `base_dir`
entirely:

```sh
space config set spaces_dir ~/work/my-spaces
```

Existing spaces are not moved — the setting changes where `space new` creates
and where `space list` looks from now on.

## Change where evergreen checkouts live (or disable them)

`src_dir` is the evergreen-checkout root that copy-on-write provisioning
prefers over network clones (see
[Evergreen, copy-on-write provisioning](../explanation/evergreen-cow-provisioning.md)).
It defaults to `<base_dir>/src`. Set it explicitly:

```sh
space config set src_dir ~/code/checkouts
```

Disable it to always clone over the network:

```sh
space config set src_dir ""
```

## Default provider and organization

Bare repo refs like `space repo add example-app` resolve against the
configured provider and organization:

```sh
space config set default_provider github.com      # or gitlab.com, …
space config set default_organization example-org
```

With both set, `example-app` means `github.com/example-org/example-app`. A
fully-qualified ref always wins over the defaults:

```sh
space repo add gitlab.com/example-org/api
```

Dry-run any resolution without cloning:

```sh
space repo resolve example-app
```

## Switch the clone protocol

Clones default to SSH (`git@github.com:example-org/example-app.git`). On a
machine without SSH keys for the forge, switch to HTTPS:

```sh
space config set git_clone_protocol https
```

Only `ssh` and `https` are accepted; anything else is rejected with an error.

## Inspect and locate the config

```sh
space config show      # every key and its current value
space config path      # print the config file path
```

`space config show` leaves unset keys blank — those are resolved at read time
from `base_dir` (`spaces_dir` → `<base_dir>/spaces`, `src_dir` →
`<base_dir>/src`). To see where the derived spaces root actually points, run
`space init` (it prints the `Spaces:` path and creates nothing new when the
files already exist) or `space path` from inside any space.

The six editable keys are: `base_dir`, `spaces_dir`, `src_dir`,
`default_provider`, `default_organization`, `git_clone_protocol`. Setting any
other key fails with the accepted list.
