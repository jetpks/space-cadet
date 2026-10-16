# frozen_string_literal: true

require "dry/monads"

module Space::Core::CLI
module Helpers
  include Dry::Monads[:result]

  # Printed before any fetch when --trust-host-key is set. The operator
  # should see the TOFU semantics at flag time — deterministic and
  # locale-independent — rather than via ssh's own "Permanently added …"
  # stderr line, which would need locale-fragile scraping to relay.
  TRUST_HOST_KEY_WARNING =
    "Warning: trusting unknown host keys on first contact (--trust-host-key); changed keys still fail verification."

  def warn_trust_host_key
    terminal.error TRUST_HOST_KEY_WARNING
  end

  # One success line per repo-addition outcome. `Added <full_name>` keeps
  # its exact historical shape (existing tests assert it); the other two
  # make idempotent adds visible — what was fetched vs skipped vs adopted.
  def repo_addition_line(result)
    full_name = result.fetch(:repo).fetch("full_name")
    case result.fetch(:outcome)
    when :present then "Already present: #{full_name}"
    when :adopted then "Registered existing checkout: #{full_name}"
    else "Added #{full_name}"
    end
  end

  def project_config
    @project_config ||= Space::Core::Config.load
  end

  def state
    @state ||= Space::Core::State.load
  end

  def store
    @store ||= Space::Core::SpaceStore.new(config: project_config, state: state)
  end

  def terminal
    @terminal
  end

  def setup_terminal(color: "auto", colors: nil)
    @terminal = Space::Core::Terminal.new(
      config: project_config,
      stdout: out,
      stderr: err,
      color_mode: colors || color || "auto"
    )
  end

  def display_date(space)
    id_date = space.id.match(/\A(\d{4})(\d{2})(\d{2})/)
    return "#{id_date[1]}-#{id_date[2]}-#{id_date[3]}" if id_date

    space.data["created_at"].to_s[0, 10]
  end

  def handle_errors
    yield
  rescue Space::Core::Error => e
    if terminal
      terminal.error(e.message)
    else
      err.puts e.message
    end
    CLI.record_outcome(Outcome.new(exit_code: 1, message: e.message))
  end

  def render(result)
    case result
    when Dry::Monads::Result::Success
      yield result.value! if block_given?
    when Dry::Monads::Result::Failure
      error = result.failure
      message = error.respond_to?(:message) ? error.message : error.to_s
      terminal ? terminal.error(message) : err.puts(message)
      CLI.record_outcome(Outcome.new(exit_code: 1, message: message))
    end
  end
end

class RepoProgress
  def initialize(total)
    @total = total
    @statuses = {}
  end

  # No fetch happens for an :adopted addition (its checkout is already on
  # disk) — label it adopting, never cloning/copying. :present additions
  # never start at all; they are marked done up front via #skip.
  def start(addition)
    repo = addition.fetch(:reference).full_name
    case addition.fetch(:outcome, :added)
    when :adopted
      @statuses[repo] = :adopting
    else
      source = addition[:src_source]
      @statuses[repo] = source&.directory? ? :copying : :cloning
    end
  end

  def skip(addition)
    @statuses[addition.fetch(:reference).full_name] = :done
  end

  def trust(addition)
    @statuses[addition.fetch(:reference).full_name] = :trusting
  end

  def finish(addition)
    @statuses[addition.fetch(:reference).full_name] = :done
  end

  def fail(addition)
    @statuses[addition.fetch(:reference).full_name] = :failed
  end

  def message
    done = @statuses.count { |_repo, status| status == :done }
    failed = @statuses.count { |_repo, status| status == :failed }
    copying = @statuses.select { |_repo, status| status == :copying }.keys
    cloning = @statuses.select { |_repo, status| status == :cloning }.keys
    adopting = @statuses.select { |_repo, status| status == :adopting }.keys
    trusting = @statuses.select { |_repo, status| status == :trusting }.keys

    if @total == 1
      copying_repo = copying.first
      cloning_repo = cloning.first
      adopting_repo = adopting.first
      trusting_repo = trusting.first
      return "Copying #{copying_repo}" if copying_repo
      return "Cloning #{cloning_repo}" if cloning_repo
      return "Adopting #{adopting_repo}" if adopting_repo
      return "Trusting #{trusting_repo}" if trusting_repo
      return "Fetch failed" if failed.positive?

      "Preparing repos"
    else
      active = []
      active << "copying #{copying.join(', ')}" unless copying.empty?
      active << "cloning #{cloning.join(', ')}" unless cloning.empty?
      active << "adopting #{adopting.join(', ')}" unless adopting.empty?
      active << "trusting #{trusting.join(', ')}" unless trusting.empty?
      suffix = active.empty? ? nil : ": #{active.join('; ')}"
      failed_text = failed.positive? ? ", #{failed} failed" : ""
      "Fetching repos #{done}/#{@total}#{failed_text}#{suffix}"
    end
  end
end
end
