require "dat/version"
require 'active_support'
require "active_support/core_ext"
require 'yaml'

module Dat
  autoload :Repository, File.dirname(__FILE__)+'/dat/repository'
end
