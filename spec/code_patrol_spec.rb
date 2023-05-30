require_relative '../lib/no-lorem'

RSpec.describe NoLorem::CodePatrol do
  before do
    @config = {
      "deny" => {
        "words" => ["lorem", "ipsum", "consectetur", "/https:\/\/example.com/"],
        "constants" => ["Some::Example", "Faker", "Example"],
      },
      "all" => true,
    }
    @patrol = NoLorem::CodePatrol.new(config: @config)
  end

  it "it finds denied word in plain string" do
    sample_code = '"lorem ipsum"'
    HEREDOC
    @patrol.examine(sample_code)
    expect(@patrol.issues?).to(be(true))
    expect(@patrol.issues.count).to(eq(2))
    expect(@patrol.issues[0].to_s).to(include("Found word 'Lorem'"))
    expect(@patrol.issues[1].to_s).to(include("Found word 'ipsum'"))

  end

  it "it finds denied words" do
    sample_code = <<~HEREDOC
    module Foo
      def self.example()
        puts "Lorem ipsum"
      end
    end
    HEREDOC
    @patrol.examine(sample_code)
    expect(@patrol.issues?).to(be(true))
    expect(@patrol.issues.count).to(eq(2))
    expect(@patrol.issues[0].to_s).to(include("Found word 'Lorem'"))
    expect(@patrol.issues[1].to_s).to(include("Found word 'ipsum'"))
  end

  it "it finds denied constants" do
    sample_code = <<~HEREDOC
    module Foo
      def self.example()
        puts Faker::Movies.title
      end

      class Other
        def info
          @info ||= Some::Example.text
        end
      end
    end
    HEREDOC
    @patrol.examine(sample_code)
    expect(@patrol.issues?).to(be(true))
    expect(@patrol.issues.count).to(eq(2))
    expect(@patrol.issues[0].to_s).to(include("Found constant 'Faker'"))
    expect(@patrol.issues[1].to_s).to(include("Found constant 'Some::Example'"))
  end

  it "finds denied regexp" do
    sample_code = <<~HEREDOC
      def default_url
        "https://example.com/hello/there"
      end
    HEREDOC
    @patrol.examine(sample_code)
    expect(@patrol.issues?).to(be(true))
    expect(@patrol.issues.count).to(eq(1))
    expect(@patrol.issues[0].to_s).to(include("Found word 'https://example.com/hello/there'"))
  end
end
