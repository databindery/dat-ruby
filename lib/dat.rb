require "dat/version"
require 'active_support'
require "active_support/core_ext"
require 'yaml'

module Dat
  autoload :Repository, File.dirname(__FILE__)+'/dat/repository'
  autoload :Diff, File.dirname(__FILE__)+'/dat/concerns/diff'
  autoload :Export, File.dirname(__FILE__)+'/dat/concerns/export'

  # dat returned an error
  class Error < RuntimeError; end

  # This error occurs when you try to execute a dat command in a directory that
  # does not contain a dat repo
  class NotARepositoryError < Dat::Error;end

  # dat was unable to auto-detect the type of data you're importing
  class AutoDetectTypeError < Dat::Error;end

  # Something went wrong calling out to dat -- the dat command was never run
  class ExecutionError < RuntimeError;end
end
