# frozen_string_literal: true

require_relative "test_helper"

# Unit tests for SCM::Git#clone's non-interactive ssh contract. Shell.run
# requires an ambient Async::Task, so every clone runs inside Sync { } (the
# Cloner::ShellRunner house pattern). The PATH-injected fake git records
# GIT_SSH_COMMAND to a log file separate from the argv log, so argv
# assertions stay exact.
class ScmGitTest < Space::CoreTest
  def test_clone_runs_ssh_with_batchmode_by_default
    run = clone_with_fake_git("git@github.com:example/repo.git")

    result = run.fetch(:result)
    assert result.success?
    assert_equal run.fetch(:dest), result.success
    assert_path_exists File.join(run.fetch(:dest), ".git")
    assert_equal "ssh -o BatchMode=yes", File.read(run.fetch(:ssh_log)).strip
    assert_equal "clone git@github.com:example/repo.git #{run.fetch(:dest)}", File.read(run.fetch(:argv_log)).strip
  ensure
    FileUtils.rm_rf(run[:setup][:root]) if run
  end

  def test_clone_with_trust_host_key_appends_accept_new
    run = clone_with_fake_git("git@github.com:example/repo.git", trust_host_key: true)

    assert run.fetch(:result).success?
    assert_equal "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new", File.read(run.fetch(:ssh_log)).strip
  ensure
    FileUtils.rm_rf(run[:setup][:root]) if run
  end

  def test_clone_appends_batchmode_to_inherited_git_ssh_command
    run = clone_with_fake_git("git@github.com:example/repo.git", git_ssh_command: "ssh -i /tmp/key")

    assert run.fetch(:result).success?
    assert_equal "ssh -i /tmp/key -o BatchMode=yes", File.read(run.fetch(:ssh_log)).strip
    # Options ride along in GIT_SSH_COMMAND; the clone argv itself is unchanged.
    assert_equal "clone git@github.com:example/repo.git #{run.fetch(:dest)}", File.read(run.fetch(:argv_log)).strip
  ensure
    FileUtils.rm_rf(run[:setup][:root]) if run
  end

  def test_clone_with_trust_host_key_appends_accept_new_to_inherited_command
    run = clone_with_fake_git("git@github.com:example/repo.git",
                              trust_host_key: true, git_ssh_command: "ssh -i /tmp/key")

    assert run.fetch(:result).success?
    assert_equal "ssh -i /tmp/key -o BatchMode=yes -o StrictHostKeyChecking=accept-new",
                 File.read(run.fetch(:ssh_log)).strip
  ensure
    FileUtils.rm_rf(run[:setup][:root]) if run
  end

  def test_clone_failure_returns_failure_with_captured_stderr
    url = "git@github.com:example/locked.git"
    run = clone_with_fake_git(url, fail_url: url)

    result = run.fetch(:result)
    assert result.failure?
    failure = result.failure
    assert_equal url, failure.fetch(:url)
    assert_equal run.fetch(:dest), failure.fetch(:dest)
    assert_match(/Host key verification failed/, failure.fetch(:stderr))
    refute_path_exists File.join(run.fetch(:dest), ".git")
  ensure
    FileUtils.rm_rf(run[:setup][:root]) if run
  end

  private

  # Installs a fake `git` on PATH that records the merged GIT_SSH_COMMAND
  # (when non-empty) and the argv to two separate logs, and can be told to
  # fail one clone URL with a fixed stderr. Returns a context hash the test
  # uses for assertions and cleanup.
  def clone_with_fake_git(url, trust_host_key: false, git_ssh_command: nil, fail_url: nil)
    setup = temp_env
    git_bin = File.join(setup.fetch(:root), "bin")
    argv_log = File.join(setup.fetch(:root), "argv.log")
    ssh_log = File.join(setup.fetch(:root), "ssh.log")
    fail_stderr = File.join(setup.fetch(:root), "fail-stderr.txt")
    File.write(fail_stderr, "Host key verification failed.\nfatal: Could not read from remote repository.\n")
    FileUtils.mkdir_p(git_bin)
    File.write(File.join(git_bin, "git"), <<~SH)
      #!/bin/sh
      if [ "$1" = "clone" ]; then
        if [ -n "$GIT_SSH_COMMAND" ]; then
          printf "%s\\n" "$GIT_SSH_COMMAND" >> "#{ssh_log}"
        fi
        printf "%s\\n" "$*" >> "#{argv_log}"
        if [ -n "$PROJECT_SPACES_CLONE_FAIL_URL" ] && [ "$2" = "$PROJECT_SPACES_CLONE_FAIL_URL" ]; then
          cat "#{fail_stderr}" >&2
          exit 1
        fi
        dest=""
        for arg in "$@"; do
          dest="$arg"
        done
        mkdir -p "$dest/.git"
        exit 0
      fi

      echo "unexpected git command: $*" >&2
      exit 1
    SH
    FileUtils.chmod("+x", File.join(git_bin, "git"))

    dest = File.join(setup.fetch(:root), "out", "repo")
    env = {
      "PATH" => "#{git_bin}:#{ENV.fetch('PATH')}",
      "PROJECT_SPACES_GIT_LOG" => argv_log,
      "PROJECT_SPACES_GIT_SSH_LOG" => ssh_log
    }
    env["GIT_SSH_COMMAND"] = git_ssh_command if git_ssh_command
    env["PROJECT_SPACES_CLONE_FAIL_URL"] = fail_url if fail_url

    result = nil
    with_env(env) do
      Sync do
        result = Space::Core::SCM::Git.new(trust_host_key: trust_host_key).clone(url, dest)
      end
    end

    {result: result, setup: setup, dest: dest, argv_log: argv_log, ssh_log: ssh_log}
  end
end
