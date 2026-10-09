# frozen_string_literal: true

require "fileutils"

module Space::Core
  # One-shot data-preserving migration from the 8.x monolith's XDG app dir to
  # this gem's (space-architect 8.x shipped Space::Core under its own identity;
  # the 9.0.0 split moved the substrate's config/state to the space-cadet app
  # dir). File-level, not dir-level: space-architect 9.0.0 still keeps its
  # session-sync cursor under the old state dir, so only the substrate's
  # config.yml / state.yml move and the old dirs are left in place. Invoked
  # from CLI.run before dispatch; no-clobber (a new file present wins, the old
  # one is left alone — no data loss); idempotent so repeated runs are safe.
  class Migration
    OLD_APP_NAME = "space-architect"

    def self.run(env: ENV, err: $stderr)
      moved = []

      old_config = XDG.config_home(env: env).join(OLD_APP_NAME, "config.yml")
      new_config = Config.default_path(env: env)
      if old_config.exist? && !new_config.exist?
        FileUtils.mkdir_p(new_config.dirname)
        FileUtils.mv(old_config, new_config)
        moved << "config"
      end

      old_state = XDG.state_home(env: env).join(OLD_APP_NAME, "state.yml")
      new_state = State.default_path(env: env)
      if old_state.exist? && !new_state.exist?
        FileUtils.mkdir_p(new_state.dirname)
        FileUtils.mv(old_state, new_state)
        moved << "state"
      end

      err.puts "space-cadet: migrated #{moved.join("/")} from #{OLD_APP_NAME}" unless moved.empty?
      moved.any?
    end
  end
end
