require "test_helper"
require "drb"
require "tmpdir"
require "fileutils"

class TestServer < Minitest::Test
  i_suck_and_my_tests_are_order_dependent!

  def setup
    @tmpdir = Dir.mktmpdir("minitest-server-test")
    @uri_file = File.join(@tmpdir, "test.uri")
    @config = Minitest::JRuby::Server::Config.new(
      uri_file: @uri_file,
      socket_dir: @tmpdir,
    )
    @daemon = Minitest::JRuby::Server::Daemon.new
  end

  def teardown
    FileUtils.rm_f(@uri_file)
    FileUtils.rm_rf(@tmpdir)
  end

  private

  def wait_for_uri_file(path)
    50.times do
      return if File.exist?(path) && File.size?(path)

      Thread.pass
      Kernel.sleep(0.01)
    end
  end

  def test_start_writes_uri_file
    server = Minitest::JRuby::Server::Server.new(daemon: @daemon, config: @config)
    thread = Thread.new { server.start }
    wait_for_uri_file(@uri_file)

    assert_path_exists @uri_file
    uri = File.read(@uri_file).strip

    assert uri.start_with?("drbunix:")
  ensure
    server&.stop
    thread&.kill
  end

  def test_stop_removes_uri_file
    server = Minitest::JRuby::Server::Server.new(daemon: @daemon, config: @config)
    thread = Thread.new { server.start }
    wait_for_uri_file(@uri_file)

    server.stop

    refute_path_exists @uri_file
  ensure
    thread&.kill
  end

  def test_daemon_accessible_via_drb
    server = Minitest::JRuby::Server::Server.new(daemon: @daemon, config: @config)
    thread = Thread.new { server.start }
    wait_for_uri_file(@uri_file)

    uri = File.read(@uri_file).strip
    begin; DRb.current_server; rescue DRb::DRbServerNotFound; DRb.start_service; end
    remote = DRbObject.new_with_uri(uri)

    assert_equal :pong, remote.ping
  ensure
    server&.stop
    thread&.kill
  end
end
