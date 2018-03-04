require "bundler/setup"

require "minitest/autorun"
require "minitest/pride"

require "shrine/storage/uploadcare"
require "dotenv"
require "forwardable"
require "stringio"

Dotenv.load!

class FakeIO
  def initialize(content)
    @io = StringIO.new(content)
  end

  extend Forwardable
  delegate %i[read rewind eof? close size] => :@io
end

class Minitest::Test
  def image
    File.open("test/fixtures/image.jpg")
  end
end
