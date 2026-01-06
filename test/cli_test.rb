# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "tempfile"
require "open3"

class CLITest < Minitest::Test
  BIN_PATH = File.expand_path("../bin/rsyntaxtree", __dir__)
  RUBY = "ruby"

  def setup
    @tmpdir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@tmpdir) if @tmpdir && Dir.exist?(@tmpdir)
  end

  # Helper to run CLI and capture output (defined at bottom as private)

  # ===================
  # Feature 1: stdin support
  # ===================

  def test_stdin_input_generates_output
    tree_data = "[S [NP test] [VP works]]"
    outfile = File.join(@tmpdir, "syntree.svg")

    result = run_cli("-f", "svg", "-o", @tmpdir, stdin_data: tree_data)

    assert result[:status].success?, "CLI should succeed with stdin input: #{result[:stderr]}"
    assert File.exist?(outfile), "Output file should be created"
    assert File.size(outfile) > 0, "Output file should not be empty"
  end

  def test_stdin_input_with_pipe_simulation
    tree_data = "[S [NP hello] [VP world]]"
    outfile = File.join(@tmpdir, "syntree.png")

    result = run_cli("-f", "png", "-o", @tmpdir, stdin_data: tree_data)

    assert result[:status].success?, "CLI should succeed with piped input"
    assert File.exist?(outfile), "PNG output file should be created"
  end

  def test_argument_takes_precedence_over_stdin
    tree_data_stdin = "[S [NP stdin] [VP data]]"
    tree_data_arg = "[S [NP arg] [VP data]]"
    outfile = File.join(@tmpdir, "syntree.svg")

    # When both arg and stdin provided, arg should win
    result = run_cli("-f", "svg", "-o", @tmpdir, tree_data_arg, stdin_data: tree_data_stdin)

    assert result[:status].success?, "CLI should succeed"
    assert File.exist?(outfile), "Output file should be created"
    content = File.read(outfile)
    assert content.include?("arg"), "Output should contain data from argument, not stdin"
  end

  def test_file_input_still_works
    tree_file = File.join(@tmpdir, "input.txt")
    File.write(tree_file, "[S [NP file] [VP input]]")
    outfile = File.join(@tmpdir, "syntree.svg")

    result = run_cli("-f", "svg", "-o", @tmpdir, tree_file)

    assert result[:status].success?, "CLI should succeed with file input"
    assert File.exist?(outfile), "Output file should be created"
    content = File.read(outfile)
    assert content.include?("file"), "Output should contain data from file"
  end

  # ===================
  # Feature 2: Config file support
  # ===================

  def test_config_file_invalid_format_shows_error
    config_file = File.join(@tmpdir, ".rsyntaxtreerc")
    File.write(config_file, <<~YAML)
      format: invalid_format
    YAML

    tree_data = "[S [NP test] [VP config]]"
    result = run_cli("-o", @tmpdir, tree_data, chdir: @tmpdir)

    refute result[:status].success?, "CLI should fail with invalid format in config"
    assert result[:stderr].include?("format") || result[:stdout].include?("format"),
           "Error should mention 'format'"
  end

  def test_config_file_invalid_fontsize_shows_error
    config_file = File.join(@tmpdir, ".rsyntaxtreerc")
    File.write(config_file, <<~YAML)
      fontsize: 999
    YAML

    tree_data = "[S [NP test] [VP config]]"
    result = run_cli("-o", @tmpdir, tree_data, chdir: @tmpdir)

    refute result[:status].success?, "CLI should fail with invalid fontsize in config"
    assert result[:stderr].include?("fontsize") || result[:stdout].include?("fontsize"),
           "Error should mention 'fontsize'"
  end

  def test_config_file_invalid_color_shows_error
    config_file = File.join(@tmpdir, ".rsyntaxtreerc")
    File.write(config_file, <<~YAML)
      color: rainbow
    YAML

    tree_data = "[S [NP test] [VP config]]"
    result = run_cli("-o", @tmpdir, tree_data, chdir: @tmpdir)

    refute result[:status].success?, "CLI should fail with invalid color in config"
    assert result[:stderr].include?("color") || result[:stdout].include?("color"),
           "Error should mention 'color'"
  end

  def test_config_file_unknown_key_shows_warning
    config_file = File.join(@tmpdir, ".rsyntaxtreerc")
    File.write(config_file, <<~YAML)
      format: svg
      unknown_option: value
    YAML

    tree_data = "[S [NP test] [VP config]]"
    outfile = File.join(@tmpdir, "syntree.svg")
    result = run_cli("-o", @tmpdir, tree_data, chdir: @tmpdir)

    # Should succeed but warn about unknown key
    assert result[:status].success?, "CLI should succeed with unknown key"
    assert File.exist?(outfile), "Output should be created"
    assert result[:stderr].include?("unknown_option") || result[:stdout].include?("unknown_option"),
           "Should warn about unknown option"
  end

  def test_config_file_shows_path_in_error
    config_file = File.join(@tmpdir, ".rsyntaxtreerc")
    File.write(config_file, <<~YAML)
      format: invalid
    YAML

    tree_data = "[S [NP test] [VP config]]"
    result = run_cli("-o", @tmpdir, tree_data, chdir: @tmpdir)

    refute result[:status].success?, "CLI should fail"
    # Error message should include the config file path
    assert result[:stderr].include?(".rsyntaxtreerc") || result[:stdout].include?(".rsyntaxtreerc"),
           "Error should mention config file path"
  end

  def test_config_file_in_current_dir
    # Create config file in tmpdir
    config_file = File.join(@tmpdir, ".rsyntaxtreerc")
    File.write(config_file, <<~YAML)
      format: svg
      color: off
      fontsize: 20
    YAML

    tree_data = "[S [NP config] [VP test]]"
    outfile = File.join(@tmpdir, "syntree.svg")

    # Run from tmpdir with config
    result = run_cli("-o", @tmpdir, tree_data, chdir: @tmpdir)

    assert result[:status].success?, "CLI should succeed with config file: #{result[:stderr]}"
    assert File.exist?(outfile), "Should output SVG as specified in config"
  end

  def test_cli_args_override_config
    config_file = File.join(@tmpdir, ".rsyntaxtreerc")
    File.write(config_file, <<~YAML)
      format: svg
    YAML

    tree_data = "[S [NP override] [VP test]]"
    outfile_png = File.join(@tmpdir, "syntree.png")

    # CLI arg -f png should override config's svg
    result = run_cli("-f", "png", "-o", @tmpdir, tree_data, chdir: @tmpdir)

    assert result[:status].success?, "CLI should succeed"
    assert File.exist?(outfile_png), "Should output PNG (CLI override)"
  end

  def test_config_file_with_custom_filename
    config_file = File.join(@tmpdir, ".rsyntaxtreerc")
    File.write(config_file, <<~YAML)
      format: svg
      outfilename: custom_tree
    YAML

    tree_data = "[S [NP custom] [VP name]]"
    outfile = File.join(@tmpdir, "custom_tree.svg")

    result = run_cli("-o", @tmpdir, tree_data, chdir: @tmpdir)

    assert result[:status].success?, "CLI should succeed"
    assert File.exist?(outfile), "Should use custom filename from config"
  end

  # ===================
  # Feature 3: Penn TreeBank format
  # ===================

  def test_penn_treebank_input
    tree_data = "(S (NP hello) (VP world))"
    outfile = File.join(@tmpdir, "syntree.svg")

    result = run_cli("-f", "svg", "-o", @tmpdir, tree_data)

    assert result[:status].success?, "CLI should succeed with Penn TreeBank input: #{result[:stderr]}"
    assert File.exist?(outfile), "Output file should be created"
    content = File.read(outfile)
    assert content.include?("hello"), "Output should contain tree content"
  end

  def test_penn_treebank_nested
    tree_data = "(S (NP (Det the) (N dog)) (VP (V runs)))"
    outfile = File.join(@tmpdir, "syntree.svg")

    result = run_cli("-f", "svg", "-o", @tmpdir, tree_data)

    assert result[:status].success?, "CLI should succeed with nested Penn TreeBank"
    assert File.exist?(outfile), "Output file should be created"
  end

  def test_penn_treebank_from_file
    tree_file = File.join(@tmpdir, "tree.penn")
    File.write(tree_file, "(S (NP test) (VP file))")
    outfile = File.join(@tmpdir, "syntree.svg")

    result = run_cli("-f", "svg", "-o", @tmpdir, tree_file)

    assert result[:status].success?, "CLI should succeed with Penn file input"
    assert File.exist?(outfile), "Output file should be created"
  end

  def test_penn_treebank_from_stdin
    tree_data = "(S (NP stdin) (VP penn))"
    outfile = File.join(@tmpdir, "syntree.svg")

    result = run_cli("-f", "svg", "-o", @tmpdir, stdin_data: tree_data)

    assert result[:status].success?, "CLI should succeed with Penn from stdin"
    assert File.exist?(outfile), "Output file should be created"
  end

  private

  # Updated helper to support chdir
  def run_cli(*args, stdin_data: nil, chdir: nil)
    cmd = [RUBY, BIN_PATH] + args
    opts = {}
    opts[:stdin_data] = stdin_data if stdin_data
    opts[:chdir] = chdir if chdir
    stdout, stderr, status = Open3.capture3(*cmd, **opts)
    { stdout: stdout, stderr: stderr, status: status }
  end
end
