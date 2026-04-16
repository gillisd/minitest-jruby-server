require "test_helper"

class ZeitwerkTest < Minitest::Test
  def test_eager_loading
    Minitest::JRuby::Server::LOADER.eager_load(force: true)

    assert_kind_of Zeitwerk::Loader, Minitest::JRuby::Server::LOADER
  end
end
