# frozen_string_literal: true

require 'warning'
Warning.ignore(/warning: parser/)

require 'byebug'
require 'parser/current'

module NoLorem
  class Issue
    attr_accessor :description, :file, :line
    def initialize(description, file:, line:)
      @description = description
      @line = line
      @file = file
    end

    def to_s
      "#{location} #{description}"
    end

    def location
      "#{file}:#{line}"
    end
  end

  class Patrol
    attr_reader :issues
    attr_reader :warnings
    attr_reader :config
    attr_reader :deny
    attr_reader :context

    WATCHLIST_KINDS = ["words", "constants"].freeze

    def initialize(config:)
      @config = config
      @deny = @config["deny"] || {}
      @warn = @config["warn"] || {}
      validate_watchlists
      reset
    end

    def reset
      @issues = []
      @warnings = []
    end

    def issues?
      issues.any?
    end

    def add_issue(description, line:)
      @issues << Issue.new(description, file: context, line: line)
    end

    def warnings?
      warnings.any?
    end

    def add_warning(description, line:)
      @warnings << Issue.new(description, file: context, line: line)
    end

    def examine_files(files)
      files = [files] if files.is_a? String
      files.each do |fname|
        examine(File.read(fname, encoding: "utf-8"), context: fname)
      end
      issues?
    end

    def examine(source, context: "(string)")
      # NOTE: this is an empty method, subclasses should call super.
      @context = context
      issues?
    end

    def watchlist_match?(watchlist, **args)
      args.each do |key, word|
        key = key.to_s
        next unless watchlist[key]
        watchlist[key].each { |expression| return true if word_matches_expression?(word, expression) }
      end
      false
    end

    def examine_constant(str, line: 0)
      str = str.to_s
      if watchlist_match?(@deny, constants: str)
        add_issue("Found constant '#{str}'", line: line)
      end
      if watchlist_match?(@warn, constants: str)
        add_warning("Found constant '#{str}'", line: line)
      end
    end

    def examine_string(str, line: 0)
      # NOTE: The code duplication between denylists and warnlists suggests that we should
      # refactor these cases into some kind of "watchlist_match" class.
      words = str.split(/\s+/)
      words.each do |word|
        if watchlist_match?(@deny, words: word)
          add_issue("Found expression '#{word}'", line: line)
          break unless @config["all"]
        end
        if watchlist_match?(@warn, words: word)
          add_warning("Found expression '#{word}'", line: line)
          break unless @config["all"]
        end
      end
    end

    private

    def word_matches_expression?(word, expression)
      if m = expression.match(/\A\/(.*)\/\Z/)
        return true if Regexp.new(m[1]).match(word)
      elsif expression.downcase == expression
        return true if word.downcase == expression.downcase
      end
      expression == word
    end

    def validate_watchlists
      if @deny.keys.length==0 && @warn.keys.length==0
        raise ArgumentError.new("No watchlist specified, please specify at least a 'denylist' or a 'warnlist'")
      end
      {denylist: @deny, warnlist: @warn}.each do |watchlist_type, watchlist|
        watchlist.keys.each do |key|
          unless WATCHLIST_KINDS.include? key
            raise ArgumentError.new("Unrecognized #{watchlist_type} type: #{key}")
          end
          unless watchlist[key].is_a? Array
            raise ArgumentError.new("#{watchlist_type} '#{key}' should be an array")
          end
        end
      end
    end
  end

  class LinePatrol < Patrol
    def initialize(**args)
      super
    end

    def examine(source, context: "(string)")
      super
      lineno = 0
      source.lines.each do |line|
        lineno += 1
        examine_string(line, line: lineno)
      end
      issues?
    end
  end

  class CodePatrol < Patrol
    def initialize(**args)
      super
      @parser = Parser::CurrentRuby.new
    end

    def examine(source, context: "(string)")
      super
      buffer = Parser::Source::Buffer.new(context, source: source)
      @parser.reset
      if ast = @parser.parse(buffer)
        traverse_ast(ast)
      end
      issues?
    end

    private

    def traverse_ast(ast)
      case ast.type
      when :str
        examine_string(ast.children.first, line: ast.location.expression.line)
      when :const
        traverse_const(ast)
      else
        ast.children.each do |child|
          traverse_ast(child) if child.is_a? Parser::AST::Node
        end
      end
    end

    def traverse_const(ast)
      if ast.type == :const
        const_name = ast.children[1].to_s
        if ast.children[0]
          const_name = traverse_const(ast.children[0]) + "::" + const_name
        end
        examine_constant(const_name, line: ast.location.expression.line)
        return const_name
      else
        return "?"
      end
    end
  end
end

