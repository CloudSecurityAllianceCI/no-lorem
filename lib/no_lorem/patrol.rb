# frozen_string_literal: true

require 'warning'
Warning.ignore(/warning: parser/)

require 'byebug'
require 'parser/current'
require_relative './watchlist'
require_relative './issue'

module NoLorem
  class Patrol
    attr_reader :issues
    attr_reader :warnings
    attr_reader :config
    attr_reader :deny
    attr_reader :context

    def initialize(config:)
      @config = config
      @deny = WatchlistSet.new(@config["deny"])
      @warn = WatchlistSet.new(@config["warn"])
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
      files = [files] if files.is_a?(String)
      files.each do |fname|
        examine(File.read(fname, encoding: "utf-8"), context: fname)
      end
      issues?
    end

    def examine(_source, context: "(string)")
      # NOTE: this is an empty method, subclasses should call super.
      @context = context
      issues?
    end

    def examine_constant(str, line: 0)
      str = str.to_s
      if @deny.constants.scan(str).any?
        add_issue("Found constant '#{str}'", line: line)
      end
      if @warn.constants.scan(str).any?
        add_warning("Found constant '#{str}'", line: line)
      end
    end

    def examine_string(str, line: 0)
      @deny.words.scan(str).each do |match|
        add_issue("Found expression '#{match}'", line: line)
        break unless @config["all"]
      end
      @warn.words.scan(str).each do |match|
        add_warning("Found expression '#{match}'", line: line)
        break unless @config["all"]
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
      if (ast = @parser.parse(buffer))
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
          traverse_ast(child) if child.is_a?(Parser::AST::Node)
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
        const_name
      else
        "?"
      end
    end
  end
end
