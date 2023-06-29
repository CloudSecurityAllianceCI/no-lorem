# frozen_string_literal: true

require 'optparse'
require 'yaml'
require 'pastel'
require 'pathname'

module NoLorem
  def self.deep_merge_hashes(original, extra)
    result = {}
    original.each do |key,val|
      if extra.key? key
        if original[key].is_a?(Hash)
          result[key] = NoLorem.deep_merge_hashes(val, extra[key])
        elsif original[key].is_a?(Array)
          result[key] = val + extra[key]
        else
          result[key] = extra[key]
        end
      else
        result[key] = val
      end
    end
    (extra.keys - original.keys).each do |key|
      result[key] = extra[key]
    end
    result
  end

  class Runner
    attr_reader :terminal

    def initialize
      @terminal = nil
    end

    def go(argv)
      parse_options(argv)
      set_terminal_coloring
      process_configuration
      generate_file_list(argv)
      print_denylists if verbose?
      process_files
    rescue => ex
      puts ex.message
      puts
      puts @option_parser
    end

    private

    def verbose?
      @config["verbose"]
    end

    def parse_options(argv)
      @options = { "exclude" => [], "deny" => {} }
      @files = []
      @option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: no-lorem [options] <path>"

        opts.on("-c", "--config FILE", "Load configuration file") do |config_file|
          @options["config"] = config_file
        end

        opts.on("-x", "--exclude PATH", "Exclude PATH from scan") do |exclude_files|
          @options["exclude"] += expand_files(exclude_files)
        end

        opts.on("-a", "--all", "Signal all errors on the same source line") do
          @options["all"] = true
        end

        opts.on("-f", "--first", "Signal first error on the same source line (default)") do
          @options["all"] = false
        end

        opts.on("--[no-]color", "Run with colored output in terminal") do |v|
          @options["color"] = v
        end

        opts.on("--verbose", "-v", "Display additional debugging information") do
          @options["verbose"] = true
        end

        opts.on("-w", "--deny-word WORD", "Add word to deny list") do |word|
          @options["deny"]["words"] = [] unless @options["deny"]["words"]
          @options["deny"]["words"] << word
        end

        opts.on("-C", "--deny-constant CONSTANT", "Add constant to deny list") do |constant|
          @options["deny"]["constants"] = [] unless @options["deny"]["words"]
          @options["deny"]["constants"] << constant
        end
      end
      @option_parser.parse!(argv)
    end

    def set_terminal_coloring
      if @options.key? "color"
        @terminal = Pastel.new(enabled: @options["color"])
      else
        @terminal = Pastel.new(enabled: $stdout.tty?)
      end
    end

    def process_configuration
      if file = configuration_file
        config = YAML.load_file(file)
        puts "Using configuration file: #{file}"
        @config = NoLorem.deep_merge_hashes(config, @options.except("config"))
      else
        @config = @options
      end
    end

    def process_files
      code_patrol = NoLorem::CodePatrol.new(config: @config)
      line_patrol = NoLorem::LinePatrol.new(config: @config)

      print "Examining #{@files.length} file(s): ["
      @files.each do |file|
        if file.end_with? ".rb"
          process_ruby_file file, with: code_patrol
        else
          process_text_file file, with: line_patrol
        end
      end
      puts "]"
      issues = code_patrol.issues + line_patrol.issues
      if issues.any?
        puts terminal.yellow("Found #{issues.length} issue(s):")
        issues.each_with_index do |issue, index|
          puts terminal.cyan(" #{index+1}) #{issue.location} ")
          puts "    " + terminal.red(issue.description)
        end
        exit 1
      end
      puts terminal.green("No issues where found. Great!")
    end

    def process_ruby_file(file, with:)
      if verbose?
        puts file
      else
        print terminal.blue("c")
      end
      with.examine_files(file)
    end

    def process_text_file(file, with:)
      if verbose?
        puts file
      else
        print terminal.blue("t")
      end
      with.examine_files(file)
    end

    def configuration_file
      return @options["config"] if @options["config"]
      candidates = ["./.no-lorem.yaml", "~/.no-lorem.yaml"]

      candidates.each do |path|
        candidate = File.expand_path(path)
        if File.exist? candidate
          return candidate
        end
      end
      puts terminal.yellow("No configuration file specified, tried default locations without success: #{candidates.join(', ')}")
      nil
    end

    def expand_files(file_or_dir)
      result = []
      if File.directory?(file_or_dir)
        Dir.glob("#{file_or_dir}/*").each do |path|
          result += expand_files(path)
        end
      else
        if file_or_dir.end_with?('.rb') ||
            file_or_dir.end_with?('.erb') ||
            file_or_dir.end_with?('.slim')
          result << Pathname.new(file_or_dir).cleanpath.to_s
        end
      end
      result
    end

    def generate_file_list(argv)
      @files = []
      if argv.length>0
        argv.each { |file_or_dir| @files += expand_files(file_or_dir) }
      else
        puts @option_parser
        puts
        puts terminal.yellow("Please specify a file or directory to analyze")
        exit 1
      end

      exclusion_list = []
      if @config["exclude"]
        @config["exclude"].each { |file_or_dir| exclusion_list += expand_files(file_or_dir) }
      end
      @files -= exclusion_list
    end

    def print_denylists
      if @config["deny"]["words"]
        puts "Denylist for words:"
        @config["deny"]["words"].each do |word|
          puts terminal.blue(" - #{word}")
        end
      else
        puts "No denylist for words."
      end
      if @config["deny"]["constants"]
        puts "Deby list for ruby constants:"
        @config["deny"]["words"].each do |constant|
          puts terminal.blue(" - #{constant}")
        end
      end
    end
  end
end
