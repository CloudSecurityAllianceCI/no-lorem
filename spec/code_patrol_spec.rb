require_relative '../lib/no-lorem'

RSpec.describe NoLorem::CodePatrol do
  before do
    @config = {
      "deny" => {
        "words" => ["lorem", "ipsum", "consectetur", "/https:\/\/example.com/"],
        "constants" => ["Some::Example", "Faker", "Example", "OptionParser"],
      },
      "all" => true,
    }
    @patrol = NoLorem::CodePatrol.new(config: @config)
  end

  it "finds denied word in plain string" do
    sample_code = '"Lorem ipsum"'
    @patrol.examine(sample_code)
    expect(@patrol.issues?).to(be(true))
    expect(@patrol.issues.count).to(eq(2))
    expect(@patrol.issues[0].to_s).to(include("Found expression 'Lorem'"))
    expect(@patrol.issues[1].to_s).to(include("Found expression 'ipsum'"))
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
    expect(@patrol.issues.count).to(eq(2))
    expect(@patrol.issues[0].to_s).to(include("Found expression 'Lorem'"))
    expect(@patrol.issues[1].to_s).to(include("Found expression 'ipsum'"))
  end

  it "finds denied constants" do
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
    expect(@patrol.issues[0].to_s).to(include("Found expression 'https://example.com/hello/there'"))
  end

  it "scans files" do
    @patrol.examine_files(["lib/no-lorem/runner.rb", "lib/no-lorem.rb"])
    expect(@patrol.issues?).to(be(true))
    expect(@patrol.issues.count).to(eq(1))
    expect(@patrol.issues[0].to_s).to(include("OptionParser"))
  end
end
