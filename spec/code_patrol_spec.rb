# frozen_string_literal: true
require_relative '../lib/no_lorem'

RSpec.describe(NoLorem::CodePatrol) do
  before do
    @config = {
      "deny" => {
        "words" => ["lorem", "ipsum", "consectetur", "/https:\/\/example.com/"],
        "constants" => ["Some::Example", "Faker", "Example"],
      },
      "warn" => {
        "words" => ["dolor", "sit", "amet", "elit"],
        "constants" => ["Pizza"],
      },
      "all" => true,
    }
    @patrol = NoLorem::CodePatrol.new(config: @config)
  end

  it "finds denied word in plain string" do
    sample_code = '"Lorem ipsum"'
    @patrol.examine(sample_code)
    expect(@patrol.issues?).to(be(true))
    expect(@patrol.warnings?).to(be(false))
    expect(@patrol.issues.count).to(eq(2))
    expect(@patrol.issues[0].to_s).to(include("Found expression 'Lorem'"))
    expect(@patrol.issues[1].to_s).to(include("Found expression 'ipsum'"))
  end

  it "finds denied word and waring word in plain string" do
    sample_code = '"Lorem ipsum dolor sit amet"'
    @patrol.examine(sample_code)
    expect(@patrol.issues?).to(be(true))
    expect(@patrol.warnings?).to(be(true))
    expect(@patrol.issues.count).to(eq(2))
    expect(@patrol.warnings.count).to(eq(3))
    expect(@patrol.issues[0].to_s).to(include("Found expression 'Lorem'"))
    expect(@patrol.issues[1].to_s).to(include("Found expression 'ipsum'"))
    expect(@patrol.warnings[0].to_s).to(include("Found expression 'dolor'"))
    expect(@patrol.warnings[1].to_s).to(include("Found expression 'sit'"))
    expect(@patrol.warnings[2].to_s).to(include("Found expression 'amet'"))
  end

  it "finds denied words" do
    sample_code = <<~HEREDOC
      module Foo
        def self.example()
          puts "Lorem ipsum"
        end
      end
    HEREDOC
    @patrol.examine(sample_code)
    expect(@patrol.issues?).to(be(true))
    expect(@patrol.warnings?).to(be(false))
    expect(@patrol.issues.count).to(eq(2))
    expect(@patrol.issues[0].to_s).to(include("Found expression 'Lorem'"))
    expect(@patrol.issues[1].to_s).to(include("Found expression 'ipsum'"))
  end

  it "finds denied constants and warnings" do
    sample_code = <<~HEREDOC
      module Foo
        def self.example()
          puts Faker::Movies.title
        end

        class Other
          include Pizza

          def info
            @info ||= Some::Example.text
          end
        end
      end
    HEREDOC
    @patrol.examine(sample_code)
    expect(@patrol.issues?).to(be(true))
    expect(@patrol.warnings?).to(be(true))
    expect(@patrol.issues.count).to(eq(2))
    expect(@patrol.warnings.count).to(eq(1))
    expect(@patrol.issues[0].to_s).to(include("Found constant 'Faker'"))
    expect(@patrol.issues[1].to_s).to(include("Found constant 'Some::Example'"))
    expect(@patrol.warnings[0].to_s).to(include("Found constant 'Pizza'"))
  end

  it "finds denied regexp" do
    sample_code = <<~HEREDOC
      def default_url
        "https://example.com/hello/there"
      end
    HEREDOC
    @patrol.examine(sample_code)
    expect(@patrol.issues?).to(be(true))
    expect(@patrol.warnings?).to(be(false))
    expect(@patrol.issues.count).to(eq(1))
    expect(@patrol.issues[0].to_s).to(include("Found expression 'https://example.com'"))
  end

  it "scans files" do
    @patrol.examine_files(["spec/support/example.rb", "spec/support/example.html.erb"])
    expect(@patrol.issues?).to(be(true))
    expect(@patrol.warnings?).to(be(false))
    expect(@patrol.issues.count).to(eq(3))
    expect(@patrol.issues[0].to_s).to(include("Faker"))
    expect(@patrol.issues[1].to_s).to(include("lorem"))
    expect(@patrol.issues[2].to_s).to(include("ipsum"))
  end
end
