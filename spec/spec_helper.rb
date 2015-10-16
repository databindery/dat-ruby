$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dat'

def sample_file(path)
  File.open(sample_file_path(path))
end

def sample_file_path(path)
  File.join(File.dirname(__FILE__), 'samples', path)
end