# frozen_string_literal: true

module NoLorem
  class Watchlist
    def initialize(expressions)
      @expressions = expressions || []
    end

    def scan(_text)
      []
    end
  end

  class WordWatchlist < Watchlist
    def initialize(expressions)
      super
    end

    def scan(text)
      results = []
      while (m = match?(text))
        results << m[0]
        text = m[1]
      end
      results
    end

    private

    def match?(text)
      @expressions.each do |expression|
        if (m = as_regex(expression))
          if text.match(Regexp.new(m))
            return [Regexp.last_match(0), Regexp.last_match.post_match]
          end
        end
        if (m = as_case_insensitive_word(expression))
          if text.match(Regexp.new("(\\W|\\A)(#{m})(\\W|\\z)", Regexp::IGNORECASE))
            return [Regexp.last_match(2), Regexp.last_match.post_match]
          end
        end
        if text.match(Regexp.new("(\\W|\\A)(#{expression})(\\W|\\z)"))
          return [Regexp.last_match(2), Regexp.last_match.post_match]
        end
      end
      nil
    end

    def as_regex(expression)
      if (m = expression.match(%r{\A/(.*)/\Z}))
        return m[1]
      end
      nil
    end

    def as_case_insensitive_word(expression)
      return expression if expression.downcase == expression
      nil
    end
  end

  class ConstantWatchlist < Watchlist
    def initialize(expressions)
      super
    end

    def scan(text)
      if @expressions.include?(text)
        return [text]
      end
      []
    end
  end

  class WatchlistSet
    WATCHLIST_KINDS = ["words", "constants"].freeze

    def initialize(watchlists)
      @watchlists = watchlists || {}
      unknown_keys = @watchlists.keys - WATCHLIST_KINDS
      if unknown_keys.any?
        raise ArgumentError, "Unknown watchlist types(s): #{unknown_keys.join(', ')}"
      end
    end

    def constants
      ConstantWatchlist.new(@watchlists["constants"])
    end

    def words
      WordWatchlist.new(@watchlists["words"])
    end
  end
end
