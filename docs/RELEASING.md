# Releasing

Releases happen when the human lands work: one release commit, one signed tag —
automation does the rest.

Where things live:

| Thing | Path |
|---|---|
| The one version constant | `lib/space_core/version.rb` (`Space::Core::VERSION`; `space version` prints it) |
| Changelog | `CHANGELOG.md` (Keep a Changelog; link refs at the bottom) |
| Release automation | `.github/workflows/release.yml` (fires on `v*` tag push) |
| Local install task | `Rakefile` → `rake install` (`gem install --user-install --no-document`) |

## 1. Release-prep commit

1. Author the new `CHANGELOG.md` section — drawn from the integrated diff.
   Match the house style: read the previous version's section and the link
   refs at the bottom first.
2. Bump `lib/space_core/version.rb`.
3. `bundle install` — refreshes the `Gemfile.lock` version lines.
4. `bundle exec rake test` — green.
5. One commit: `Release X.Y.Z: changelog, version bump, lockfile`.

## 2. Merge, then tag — annotated, signed, on the merge commit

The human merges the PR on GitHub, then:

```sh
git checkout main && git pull
grep VERSION lib/space_core/version.rb   # the bump is on main
```

Tag message in a file: subject `Release X.Y.Z: <one-line summary>`. Then:

```sh
git tag -s vX.Y.Z -F <message file>
git tag -v vX.Y.Z                          # signature verifies
git push origin vX.Y.Z
git ls-remote --tags origin | grep vX.Y.Z  # tag is on the remote
```

## 3. Automation takes it from the tag

`release.yml` on the tag push: builds the gem, publishes to RubyGems via
trusted publishing (OIDC — no API token), smoke-tests an install from the
live index, and creates the GitHub Release with generated notes and the
`.gem` attached. Tags containing `.rc` / `.beta` / `.alpha` / `.pre` / `-`
are marked prerelease and never become "latest". No manual step here — watch
it land:

```sh
gh run watch
gh release view vX.Y.Z
```

## 4. Update the local CLI — and actually verify it

```sh
git checkout main && git pull   # the released tree, not a working branch
bundle exec rake install
space version               # must print X.Y.Z
```

The verify line is not optional. Binstubs in `~/.gem/ruby/<abi>/bin` carry
the shebang of whichever ruby installed them and shadow the current mise
ruby's own bin dir on PATH; after a mise ruby upgrade, a stale binstub
silently keeps running the last gem the *old* ruby saw.
`rake install` targets the user gem home, which regenerates that binstub
under the current ruby.
