require "test_helper"

class ZeitwerkTest < Minitest::Test
  def test_eager_loading
    Minitest::Jruby::Server::LOADER.eager_load(force: true)

    assert_kind_of Zeitwerk::Loader, Minitest::Jruby::Server::LOADER
  end
end
