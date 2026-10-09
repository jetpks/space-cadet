# frozen_string_literal: true

require_relative "test_helper"
require "pastel"

# Covers the colourful help listing (lib/space_core/cli/help.rb) and the
# Dry::CLI::Usage reopen that routes every namespace listing through it. The
# help machinery lives in Space::Core::CLI and serves the `space` binary.
class HelpTest < Space::CoreTest
  def space_root = Space::Core::CLI::Registry.get([])
  def core_config_ns = Space::Core::CLI::Registry.get(["config"])

  # The `space` listing declares no phase → single default listing, no phase
  # headers, alpha-sorted — byte-unchanged from before.
  def test_space_help_stays_ungrouped_and_alpha_sorted
    with_program_name("space") do
      plain = Space::Core::CLI::Help.call(space_root, pastel: Pastel.new(enabled: false))

      assert_operator plain.index("space build"), :<, plain.index("space config")
      assert_operator plain.index("space status"), :<, plain.index("space use")
      assert_match(/space status \[REST\]\s+# Set a space status/, plain)
    end
  end

  def test_plain_listing_has_no_ansi_but_keeps_dry_cli_tokens
    plain = Space::Core::CLI::Help.call(space_root, pastel: Pastel.new(enabled: false))

    refute_match(/\e\[/, plain, "plain listing must not contain ANSI escapes")
    assert_match("Commands:", plain)
    assert_match(/repo \[SUBCOMMAND\]/, plain)
    assert_match(/shell \[SUBCOMMAND\]/, plain)
  end

  def test_colored_listing_emits_ansi_escapes
    colored = Space::Core::CLI::Help.call(space_root, pastel: Pastel.new(enabled: true))

    assert_match(/\e\[/, colored, "colored listing must contain ANSI escapes")
  end

  def test_root_listing_carries_a_header_and_footer
    plain = Space::Core::CLI::Help.call(space_root, pastel: Pastel.new(enabled: false))

    assert_match("space-cadet", plain)
    assert_match(/Run `.*--help`/, plain)
  end

  # A host binary sharing this renderer (the architect binary) brands the
  # header with its own name and version, not the substrate's.
  def test_host_product_overrides_the_header_brand
    with_product("architect", "9.0.0") do
      plain = Space::Core::CLI::Help.call(space_root, pastel: Pastel.new(enabled: false))

      assert_match(/\Aarchitect 9\.0\.0 — /, plain)
      refute_match(/space-cadet \d/, plain)
    end
  end

  def test_namespace_does_not_double_the_program_name
    with_program_name("space") do
      plain = Space::Core::CLI::Help.call(core_config_ns, pastel: Pastel.new(enabled: false))

      refute_match(/space space/, plain)
      assert_match(/space config show/, plain)
    end
  end

  def test_usage_reopen_delegates_to_help
    assert_equal Space::Core::CLI::Help.call(space_root, pastel: Pastel.new(enabled: false)),
                 with_program_name($PROGRAM_NAME) { plain_usage(space_root) }
  end

  private

  def plain_usage(result)
    Space::Core::CLI.help_pastel = Pastel.new(enabled: false)
    Dry::CLI::Usage.call(result)
  end

  def with_program_name(name)
    original = $PROGRAM_NAME
    $PROGRAM_NAME = name
    yield
  ensure
    $PROGRAM_NAME = original
  end

  def with_product(name, version)
    Space::Core::CLI::Help.product_name = name
    Space::Core::CLI::Help.product_version = version
    yield
  ensure
    Space::Core::CLI::Help.product_name = nil
    Space::Core::CLI::Help.product_version = nil
  end
end
