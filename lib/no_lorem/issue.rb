# frozen_string_literal: true

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
end
