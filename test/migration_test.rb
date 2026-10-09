# frozen_string_literal: true

require "test_helper"
require "space_core/migration"

class MigrationTest < Space::CoreTest
  Migration = Space::Core::Migration
  OLD_APP_NAME = Migration::OLD_APP_NAME

  def with_old_layout
    root = temp_env
    env = root.fetch(:env)
    old_config_dir = File.join(root.fetch(:root), "xdg-config", OLD_APP_NAME)
    old_state_dir = File.join(root.fetch(:root), "xdg-state", OLD_APP_NAME)
    yield(env, old_config_dir, old_state_dir)
  ensure
    FileUtils.remove_entry(root.fetch(:root)) if root[:root]
  end

  def test_migrates_config_and_state_files_byte_intact
    with_old_layout do |env, old_config_dir, old_state_dir|
      FileUtils.mkdir_p(old_config_dir)
      FileUtils.mkdir_p(old_state_dir)
      File.write(File.join(old_config_dir, "config.yml"), "base_dir: /some/path\n")
      File.write(File.join(old_state_dir, "state.yml"), "current_space: demo\n")

      err = StringIO.new
      Migration.run(env: env, err: err)

      assert_equal "base_dir: /some/path\n",
                   File.read(File.join(env.fetch("XDG_CONFIG_HOME"), "space-cadet", "config.yml"))
      assert_equal "current_space: demo\n",
                   File.read(File.join(env.fetch("XDG_STATE_HOME"), "space-cadet", "state.yml"))
      refute File.exist?(File.join(old_config_dir, "config.yml")), "old config should have moved"
      refute File.exist?(File.join(old_state_dir, "state.yml")), "old state should have moved"
      assert_match(/migrated config\/state from #{OLD_APP_NAME}/, err.string)
    end
  end

  def test_leaves_the_old_state_dir_and_foreign_files_in_place
    with_old_layout do |env, _old_config_dir, old_state_dir|
      # space-architect 9.0.0 still owns session-sync.yaml under the old dir —
      # the migration is file-level and must not touch it.
      FileUtils.mkdir_p(old_state_dir)
      File.write(File.join(old_state_dir, "state.yml"), "current_space: demo\n")
      File.write(File.join(old_state_dir, "session-sync.yaml"), "cursor: kept\n")

      Migration.run(env: env, err: StringIO.new)

      assert File.directory?(old_state_dir), "old state dir survives (session-sync still lives there)"
      assert_equal "cursor: kept\n", File.read(File.join(old_state_dir, "session-sync.yaml"))
    end
  end

  def test_second_run_is_a_no_op
    with_old_layout do |env, old_config_dir, _old_state_dir|
      FileUtils.mkdir_p(old_config_dir)
      File.write(File.join(old_config_dir, "config.yml"), "base_dir: /some/path\n")
      Migration.run(env: env, err: StringIO.new)

      err = StringIO.new
      refute Migration.run(env: env, err: err)
      assert_empty err.string
      assert_equal "base_dir: /some/path\n",
                   File.read(File.join(env.fetch("XDG_CONFIG_HOME"), "space-cadet", "config.yml"))
    end
  end

  def test_no_clobber_when_the_new_file_already_exists
    with_old_layout do |env, old_config_dir, _old_state_dir|
      FileUtils.mkdir_p(old_config_dir)
      FileUtils.mkdir_p(File.join(env.fetch("XDG_CONFIG_HOME"), "space-cadet"))
      File.write(File.join(old_config_dir, "config.yml"), "base_dir: /old\n")
      File.write(File.join(env.fetch("XDG_CONFIG_HOME"), "space-cadet", "config.yml"), "base_dir: /new\n")

      Migration.run(env: env, err: StringIO.new)

      assert_equal "base_dir: /new\n",
                   File.read(File.join(env.fetch("XDG_CONFIG_HOME"), "space-cadet", "config.yml"))
      assert File.exist?(File.join(old_config_dir, "config.yml")), "old file is left, not deleted"
    end
  end

  def test_clean_home_is_silent
    with_old_layout do |env, _old_config_dir, _old_state_dir|
      err = StringIO.new

      refute Migration.run(env: env, err: err)
      assert_empty err.string
    end
  end

end
