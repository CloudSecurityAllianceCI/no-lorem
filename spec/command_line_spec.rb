require_relative '../lib/no-lorem'

RSpec.describe NoLorem::Runner do
  it "returns a 0 status code if no error found" do
    scan = `bin/no-lorem -w foobar spec/support`
    expect($?.success?).to(be(true))
  end

  it "scans files for first errors on each line" do
    scan = `bin/no-lorem -c no-lorem.sample.yaml spec/support`
    expect($?.success?).to(be(false))
    expect(scan).to(include("Found 3 issue(s)"))
    expect(scan).to(include("Found constant 'Faker'"))
    expect(scan).to(include("Found expression 'lorem'"))
    expect(scan).to(include("Found expression 'enim'"))
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

