# Space Cadet 🪐

[![Gem Version](https://badge.fury.io/rb/space-cadet.svg)](https://badge.fury.io/rb/space-cadet)

> **Task-scoped project workspaces — for humans and their agents!** ✨🌌

`space-cadet` is a Ruby gem for **spaces** — task-scoped project workspaces
that hold repos, notes, and artifacts under one obvious filesystem root. One
binary, **`space`**, over the `Space::Core` library. It pairs with
[jetpks/space-architect](https://github.com/jetpks/space-architect) (the
Architect Loop, which runs on top of spaces) and
[jetpks/repo-tender](https://github.com/jetpks/repo-tender) (which tends the
evergreen checkouts spaces provision from).

**Lineage:** this repo is the space tool's original home (the v1.0.0 era); the
tool was absorbed into space-architect (up to 8.0.0) and is extracted back out
here as of 9.0.0.

## Installation 📦

```sh
gem install space-cadet
```

or add `gem "space-cadet"` to your `Gemfile` and `bundle install`. The gem
installs one executable, `space`. 🎀

## 60-second start 🚀

```sh
space init                          # create XDG config + state files
space new "My First Space"          # blast off a new space 🪐
cd ~/architect/spaces/*my-first-space
space status                        # report where you are
```

Full learning journey: [your first space](docs/tutorials/first-space.md).

## Documentation 📖

Organized by [Diátaxis](https://diataxis.fr/) — pick the quadrant that matches
what you're here for:

| I want to… | Go to |
|---|---|
| **learn** the tool step by step | [Tutorials](docs/tutorials/) |
| **get something done** (a recipe) | [How-to guides](docs/how-to/) |
| **look up** a command, flag, or path | [Reference](docs/reference/) |
| **understand** why it works this way | [Explanation](docs/explanation/) |

## Development 🛠️

```sh
bundle install
bundle exec rake test       # the minitest suite
bundle exec rake build      # build the gem into pkg/
bundle exec rake install    # build + install into your user gem home
```

## Contributing 💝

Bug reports and pull requests are welcome on GitHub at
[https://github.com/jetpks/space-cadet](https://github.com/jetpks/space-cadet)!

## License 📄

Available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

---

Made with 💖 and fibers 🧵 by Eric
