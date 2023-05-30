#! /usr/bin/env ruby
# frozen_string_literal: true

libx = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(libx) unless $LOAD_PATH.include?(libx)
require 'no-lorem'

NoLorem::Runner.new.go(ARGV)

