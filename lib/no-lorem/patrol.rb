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
    attr_reader :config
    attr_reader :deny
    attr_reader :context

    DENYLIST_KINDS = ["words", "constants"]

    def initialize(config:)
      @issues = []
      @config = config
      @deny = @config["deny"]
      validate_deny_lists
    end

    def reset
      @issues = []
    end

    def issues?
      issues.any?
    end

    def add_issue(description, line:)
      @issues << Issue.new(description, file: context, line: line)
    end

    def examine_files(files)
      files = [files] if files.is_a? String
      files.each do |fname|
        examine(File.read(fname), context: fname)
      end
      issues?
    end

    def examine(source, context: "(string)")
      @context = context
      issues?
    end

    def watchlist_match?(**args)
      args.each do |key, word|
        key = key.to_s
        next unless @deny[key]
        @deny[key].each do |expression|
          if m = expression.match(/\A\/(.*)\/\Z/)
            return true if Regexp.new(m[1]).match(word)
          elsif expression.downcase == expression
            return true if word.downcase == expression.downcase
          end
          return true if expression == word
        end
      end
      false
    end

    def examine_constant(str, line: 0)
      str = str.to_s
      if watchlist_match?(constants: str)
        add_issue("Found constant '#{str}'", line: line)
      end
    end

    def examine_string(str, line: 0)
      words = str.split(/\s+/)
      words.each do |word|
        if watchlist_match?(words: word)
          add_issue("Found expression '#{word}'", line: line)
          break unless @config["all"]
        end
      end
    end

    private
    def validate_deny_lists
      unless @deny && @deny.keys.length>0
        raise ArgumentError.new("No deny list specified")
      end
      @deny.keys.each do |key|
        unless DENYLIST_KINDS.include? key
          raise ArgumentError.new("Unrecognized denylist: #{key}")
        end
        unless @deny[key].is_a? Array
          raise ArgumentError.new("Denylist '#{key}' should be an array")
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

