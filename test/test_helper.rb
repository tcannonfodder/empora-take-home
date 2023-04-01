# frozen_string_literal: true

Bundler.require(:test)
SimpleCov.start do
  add_filter "/test/"
end


require 'webmock/minitest'
WebMock.enable!

require 'mocha/minitest'

require_relative 'test_helper/declarative_test_patch'

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"

require_relative "../lib/address_csv_transformer"
require_relative "../lib/address_verification_client"
