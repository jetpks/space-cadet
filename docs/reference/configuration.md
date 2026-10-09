# Configuration reference ⚙️

The `space` CLI's config and state: file paths, keys, defaults, and derived
values. Facts only — for guided setup see
[Configure spaces and repos](../how-to/configure-spaces-and-repos.md).

## Files and XDG paths

| What | Path |
|---|---|
| Config | `$XDG_CONFIG_HOME/space-cadet/config.yml` (default `~/.config/space-cadet/config.yml`) |
| State | `$XDG_STATE_HOME/space-cadet/state.yml` (default `~/.local/state/space-cadet/state.yml`) |
| Spaces root | `<base_dir>/spaces` by default |
| Evergreen-checkout root (`src_dir`) | `<base_dir>/src` by default |

All three roots honor the XDG env vars (`XDG_CONFIG_HOME`, `XDG_STATE_HOME`)
and `HOME`. `space init` creates the config and state files (with defaults)
plus the spaces directory; `space config path` prints the config path.

## `config.yml`

Defaults, as written by `space init`:

```yaml
version: 1
base_dir: ~/architect            # spaces_dir + src_dir hang off this by default
default_provider: github.com
default_organization:
git_clone_protocol: ssh          # ssh | https
```

### Keys

| Key | Default | Meaning |
|---|---|---|
| `version` | `1` | Config file format version. Not editable. |
| `base_dir` | `~/architect` | Root under which the other trees hang. `~` is expanded. |
| `spaces_dir` | *(unset)* → `<base_dir>/spaces` | Where `space new` creates spaces and `space list` looks. |
| `src_dir` | *(unset)* → `<base_dir>/src` | Evergreen-checkout root for copy-on-write provisioning. Set to `""` to disable COW (always clone). |
| `default_provider` | `github.com` | Forge assumed for bare repo refs like `example-app`. |
| `default_organization` | *(unset)* | Organization assumed for bare repo refs. |
| `git_clone_protocol` | `ssh` | `ssh` or `https`; clone URLs are built accordingly (`git@github.com:owner/name.git` vs `https://github.com/owner/name.git`). |

Only these six keys are editable via `space config set KEY VALUE`
(`version` is managed by the tool): `base_dir`, `spaces_dir`, `src_dir`,
`default_provider`, `default_organization`, `git_clone_protocol`. Setting an
unknown key fails with the accepted list. Setting `git_clone_protocol` to
anything but `ssh` or `https` fails at both set time and read time.

### Derived values

`spaces_dir` and `src_dir` default dynamically from `base_dir`: unset keys
render blank in `space config show`, and the effective values resolve at read
time as `<base_dir>/spaces` and `<base_dir>/src`. Setting either explicitly
overrides the derivation; setting `src_dir` to an empty string disables the
evergreen checkout entirely.

## State

`state.yml` holds recent-space state recorded by `space use` — it powers the
`Recent space:` line in `space list` output. It is tool-managed; edit it by
running commands (`space use IDENTIFIER`), not by hand.
