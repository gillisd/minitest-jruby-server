require "test_helper"
require "drb"
require "tmpdir"
require "fileutils"

class TestClient < Minitest::Test
  def test_raises_server_not_running_when_no_uri_file
    missing = File.join(Dir.mktmpdir, "nonexistent.uri")
    config = Minitest::JRuby::Server::Config.new(uri_file: missing)
    client = Minitest::JRuby::Server::Client.new(config: config)

    assert_raises Minitest::JRuby::Server::ServerNotRunning do
      client.connect
    end
  end

  def test_connect_to_real_server
    with_server do |config|
      client = Minitest::JRuby::Server::Client.new(config: config)
      client.connect

      assert_predicate client, :connected?

      info = client.info

      assert_kind_of Hash, info
      assert info.key?(:pid)
    end
  end

  def test_run_tests_returns_result_hash
    with_server do |config|
      client = Minitest::JRuby::Server::Client.new(config: config)
      client.connect
      result = client.run_tests(seed: 42)

      assert_kind_of Hash, result
      assert result.key?(:tests)
      assert result.key?(:passed)
    end
  end

  private

  def with_server
    tmpdir = Dir.mktmpdir("minitest-client-test")
    uri_file = File.join(tmpdir, "test.uri")
    config = Minitest::JRuby::Server::Config.new(uri_file: uri_file, socket_dir: tmpdir)
    daemon = Minitest::JRuby::Server::Daemon.new
    server = Minitest::JRuby::Server::Server.new(daemon: daemon, config: config)
    thread = Thread.new { server.start }
    50.times {
      break if File.exist?(uri_file) && File.size?(uri_file)

      Thread.pass
      Kernel.sleep(0.01)
    }

    yield config
  ensure
    server&.stop
    thread&.kill
    FileUtils.rm_rf(tmpdir)
  end
end
