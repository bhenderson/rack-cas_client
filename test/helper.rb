require 'minitest/autorun'
require 'rack/cas_client'
require 'rack/test'
require 'json'

class TestRack < MiniTest::Unit::TestCase
end
class TestRack::TestCASClient < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def setup
    app = lambda{|env|
      request = Rack::Request.new(env)
      [200,
        {'Content-Type' => 'text/plain'},
        [request.session[:cas_user].to_json]]
    }
    @session = {}
    @env = {'rack.session' => @session}
    @client = Rack::CASClient.new app, cas_base_url: 'http://example/cas'
    @mock_request = MiniTest::Mock.new
    @client.instance_variable_set :@request, @mock_request
  end

  def teardown
    @mock_request.verify
  end

  def app
    @app ||= Rack::Lint.new @client
  end

  def assert_request_url_without_ticket expected, url
    expected[/^/] = 'http://example'
    url[/^/]      = 'http://example'

    browser = Rack::Test::Session.new(lambda{|e| [200, {},['']]})
    browser.get url
    @client.instance_variable_set :@request, browser.last_request

    actual = @client.request_url_without_ticket

    assert_equal expected, actual
    assert_equal url, @client.request.url, "expected url to be unmodified"
  end
end
