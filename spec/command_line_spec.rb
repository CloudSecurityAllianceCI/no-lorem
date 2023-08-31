# frozen_string_literal: true
require 'English'
require_relative '../lib/no_lorem'

RSpec.describe(NoLorem::Runner) do
  it "returns a 0 status code if no error found" do
    scan = %x(bin/no-lorem -W foobar spec/support)
    expect($CHILD_STATUS.success?).to(be(true))
    expect(scan).to(include("No blocking issues where found."))
  end

  it "returns a 1 status code if a denied word was found" do
    scan = %x(bin/no-lorem -W lorem spec/support)
    expect($CHILD_STATUS.success?).to(be(false))
    expect(scan).to(include("Found 1 issue(s)"))
  end

  it "returns a 1 status code if a denied constant was found" do
    scan = %x(bin/no-lorem -K Faker spec/support)
    expect($CHILD_STATUS.success?).to(be(false))
    expect(scan).to(include("Found 1 issue(s)"))
  end

  it "returns a 0 status code if a warning word was found" do
    scan = %x(bin/no-lorem -w lorem spec/support)
    expect($CHILD_STATUS.success?).to(be(true))
    expect(scan).to(include("Found 1 warning(s)"))
  end

  it "returns a 2 status code if it can't process any file" do
    %x(bin/no-lorem -w lorem ./foobar)
    expect($CHILD_STATUS.exitstatus).to(be(2))
  end

  it "returns a 2 status code if it can't process the config file" do
    %x(bin/no-lorem -c foobar.yaml spec/support)
    expect($CHILD_STATUS.exitstatus).to(be(2))
  end

  it "scans files for first errors on each line" do
    scan = %x(bin/no-lorem -c no-lorem.sample.yaml spec/support)
    expect($CHILD_STATUS.success?).to(be(false))
    expect(scan).to(include("Found 3 issue(s)"))
    expect(scan).to(include("Found constant 'Faker'"))
    expect(scan).to(include("Found expression 'lorem'"))
    expect(scan).to(include("Found expression 'enim'"))
    expect(scan).to(include("Found 1 warning(s)"))
    expect(scan).to(include("Found expression 'TODO:'"))
  end

  it "scans files for all errors on each line" do
    scan = %x(bin/no-lorem --all --config no-lorem.sample.yaml spec/support)
    expect($CHILD_STATUS.success?).to(be(false))
    expect(scan).to(include("Found 11 issue(s)"))
    expect(scan).to(include("Found constant 'Faker'"))
    ["lorem",
     "ipsum",
     "enim",
     "minim",
     "veniam",
     "nostrud",
     "exercitation",
     "ullamco",
     "aliquip",
     "consequat"].each do |word|
      expect(scan).to(include("Found expression '#{word}'"))
    end
  end

  it "scans files for errors excluding a file" do
    scan = %x(bin/no-lorem -c no-lorem.sample.yaml -x spec/support/example.html.erb spec/support)
    expect($CHILD_STATUS.success?).to(be(false))
    expect(scan).to(include("Found 2 issue(s)"))
    expect(scan).to(include("Found constant 'Faker'"))
    expect(scan).to(include("Found expression 'lorem'"))
  end
end
