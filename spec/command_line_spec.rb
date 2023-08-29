require_relative '../lib/no-lorem'

RSpec.describe NoLorem::Runner do
  it "returns a 0 status code if no error found" do
    scan = `bin/no-lorem -W foobar spec/support`
    expect($?.success?).to(be(true))
    expect(scan).to(include("No blocking issues where found."))
  end

  it "returns a 1 status code if a denied word was found" do
    scan = `bin/no-lorem -W lorem spec/support`
    expect($?.success?).to(be(false))
    expect(scan).to(include("Found 1 issue(s)"))
  end

  it "returns a 1 status code if a denied constant was found" do
    scan = `bin/no-lorem -K Faker spec/support`
    expect($?.success?).to(be(false))
    expect(scan).to(include("Found 1 issue(s)"))
  end

  it "returns a 0 status code if a warning was found" do
    scan = `bin/no-lorem -w lorem spec/support`
    expect($?.success?).to(be(true))
    expect(scan).to(include("Found 1 warning(s)"))
  end

  it "scans files for first errors on each line" do
    scan = `bin/no-lorem -c no-lorem.sample.yaml spec/support`
    expect($?.success?).to(be(false))
    expect(scan).to(include("Found 3 issue(s)"))
    expect(scan).to(include("Found constant 'Faker'"))
    expect(scan).to(include("Found expression 'lorem'"))
    expect(scan).to(include("Found expression 'enim'"))
    expect(scan).to(include("Found 1 warning(s)"))
    expect(scan).to(include("Found expression 'TODO:'"))
  end

  it "scans files for all errors on each line" do
    scan = `bin/no-lorem --all --config no-lorem.sample.yaml spec/support`
    expect($?.success?).to(be(false))
    expect(scan).to(include("Found 9 issue(s)"))
    expect(scan).to(include("Found constant 'Faker'"))
    ["lorem", "ipsum", "enim", "minim", "nostrud", "exercitation", "ullamco", "aliquip"].each do |word|
      expect(scan).to(include("Found expression '#{word}'"))
    end
  end

  it "scans files for errors excluding a file" do
    scan = `bin/no-lorem -c no-lorem.sample.yaml -x spec/support/example.html.erb spec/support`
    expect($?.success?).to(be(false))
    expect(scan).to(include("Found 2 issue(s)"))
    expect(scan).to(include("Found constant 'Faker'"))
    expect(scan).to(include("Found expression 'lorem'"))
  end
end

