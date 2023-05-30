require 'optparse'
require 'yaml'

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
      result
    end
  end

  class Runner
    def initialize
    end

    def go(argv)
      parse_options(argv)
      generate_file_list(argv)
      process_configuration
      process_files
    rescue => ex
      puts ex.message
      puts
      puts @option_parser
    end

    def parse_options(argv)
      @options = { "exclude" => [], "deny" => {} }
      @files = []
      @option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: no-lorem.rb [options] <path>"

        opts.on("-c", "--config FILE", "Load configuration file") do |config_file|
          @options["config"] = config_file
        end

        opts.on("-x", "--exclude PATH", "Exclude PATH from scan") do |exclude_files|
          @options["exclude"] += expand_files(exclude_files)
        end

        opts.on("-a", "--all", "Signal all errors on the same source line") do
          @options["all"] = true
        end

        opts.on("-f", "--first", "Signal first error on the same source line") do
          @options["all"] = false
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

    def process_configuration
      if file = configuration_file
        config = YAML.load_file(file)
        puts "Using configuration file: #{file}"
        @config = NoLorem.deep_merge_hashes(config.except("config"), @options)
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
          putc "c"
          code_patrol.examine_files(file)
        else
          putc "."
          line_patrol.examine_files(file)
        end
      end
      puts "]"
      issues = code_patrol.issues + line_patrol.issues
      if issues.any?
        puts "Found #{issues.length} issue(s):"
        issues.each_with_index do |issue, index|
          puts " #{index}) #{issue}"
        end
        exit 1
      end
      puts "No issues where found. Great!"
    end

    private

    def configuration_file
      return @options["config"] if @options["config"]
      candidates = ["./.no-lorem.yaml", "~/.no-lorem.yaml"]

      candidates.each do |path|
        candidate = File.expand_path(path)
        if File.exist? candidate
          return candidate
        end
      end
      puts "No configuration file specified, tried default locations without success: #{candidates.join(', ')}"
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
            file_or_dir.end_with?('.html.erb') ||
            file_or_dir.end_with?('.html.slim')
          result << File.expand_path(file_or_dir)
        end
      end
      result
    end

    def generate_file_list(argv)
      @files = []
      if argv.length>0
        argv.each { |file_or_dir| @files += expand_files(file_or_dir) }
      else
        puts option_parser
        puts
        puts "Please specify a file or directory to analyze"
        exit 1
      end

      @files -= @options["exclude"]
    end
  end
end
