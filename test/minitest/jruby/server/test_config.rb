require "test_helper"
require "tmpdir"

class TestConfig < Minitest::Test
  def test_default_project_root_is_pwd
    config = Minitest::Jruby::Server::Config.new

    assert_equal Dir.pwd, config.project_root
  end

  def test_custom_project_root
    config = Minitest::Jruby::Server::Config.new(project_root: "/tmp/myproject")

    assert_equal "/tmp/myproject", config.project_root
  end

  def test_default_uri_file_in_project_root
    config = Minitest::Jruby::Server::Config.new(project_root: "/tmp/myproject")

    assert_equal "/tmp/myproject/.minitest-jruby.uri", config.uri_file
  end

  def test_custom_uri_file
    config = Minitest::Jruby::Server::Config.new(uri_file: "/custom/path.uri")

    assert_equal "/custom/path.uri", config.uri_file
  end

  def test_default_test_paths
    config = Minitest::Jruby::Server::Config.new

    assert_equal ["test/**/*_test.rb", "test/**/test_*.rb"], config.test_paths
  end

  def test_default_load_paths
    config = Minitest::Jruby::Server::Config.new

    assert_equal ["lib", "test"], config.load_paths
  end

  def test_default_connect_timeout
    config = Minitest::Jruby::Server::Config.new

    assert_equal 5, config.connect_timeout
  end

  def test_socket_dir_defaults_to_tmpdir
    config = Minitest::Jruby::Server::Config.new

    assert_equal Dir.tmpdir, config.socket_dir
  end

  def test_socket_path_includes_pid
    config = Minitest::Jruby::Server::Config.new

    assert_match(/minitest_jruby\.\d+$/, config.socket_path)
  end

  def test_uri_includes_drbunix_scheme
    config = Minitest::Jruby::Server::Config.new

    assert config.uri.start_with?("drbunix:")
  end
end
