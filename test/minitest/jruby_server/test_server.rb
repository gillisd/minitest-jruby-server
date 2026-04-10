require "test_helper"
require "drb"
require "tmpdir"
require "fileutils"

class TestServer < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir("minitest-server-test")
    @uri_file = File.join(@tmpdir, "test.uri")
    @config = Minitest::JRubyServer::Config.new(
      uri_file: @uri_file,
      socket_dir: @tmpdir
    )
    @daemon = Minitest::JRubyServer::Daemon.new
  end

  def teardown
    File.delete(@uri_file) if File.exist?(@uri_file)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_start_writes_uri_file
    server = Minitest::JRubyServer::Server.new(daemon: @daemon, config: @config)
    thread = Thread.new { server.start }
    Thread.pass until File.exist?(@uri_file)

    assert File.exist?(@uri_file)
    uri = File.read(@uri_file).strip
    assert uri.start_with?("drbunix:")
  ensure
    server&.stop
    thread&.kill
  end

  def test_stop_removes_uri_file
    server = Minitest::JRubyServer::Server.new(daemon: @daemon, config: @config)
    thread = Thread.new { server.start }
    Thread.pass until File.exist?(@uri_file)

    server.stop
    refute File.exist?(@uri_file)
  ensure
    thread&.kill
  end

  def test_daemon_accessible_via_drb
    server = Minitest::JRubyServer::Server.new(daemon: @daemon, config: @config)
    thread = Thread.new { server.start }
    Thread.pass until File.exist?(@uri_file)

    uri = File.read(@uri_file).strip
    DRb.start_service
    remote = DRbObject.new_with_uri(uri)
    assert_equal :pong, remote.ping
  ensure
    server&.stop
    thread&.kill
  end
end
