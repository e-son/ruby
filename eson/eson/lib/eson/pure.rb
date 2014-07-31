if ENV['SIMPLECOV_COVERAGE'].to_i == 1
  require 'simplecov'
  SimpleCov.start do
    add_filter "/tests/"
  end
end
require_relative '../eson/common'
require_relative 'pure/parser'
require_relative 'pure/generator'

module ESON
  # This module holds all the modules/classes that implement ESON's
  # functionality in pure ruby.
  module Pure
    $DEBUG and warn "Using Pure library for ESON."
    ESON.parser = Parser
    ESON.generator = Generator
  end

  ESON_LOADED = true unless defined?(::ESON::ESON_LOADED)
end
