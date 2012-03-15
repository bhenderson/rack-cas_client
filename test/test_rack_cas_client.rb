require 'helper'

class TestRack::TestCASClient
  def test_all_ready_authd
    @session[:cas_user] = {'username' => 'me'}
    get '/', {}, @env
    assert_equal '{"username":"me"}', last_response.body
  end

  def test_redirects_to_cas_server
    get '/'
    assert last_response.redirect?

    expected = 'http://example/cas/login?service=http%3A%2F%2Fexample.org%2F'
    assert_equal expected, last_response['Location']

    get '/foo?q=bar'
    assert last_response.redirect?

    expected = 'http://example/cas/login?service=http%3A%2F%2Fexample.org%2Ffoo%3Fq%3Dbar'
    assert_equal expected, last_response['Location']
  end

  def test_request_url
    assert_request_url_without_ticket '/', '/?ticket=123'
    assert_request_url_without_ticket '/?foo=bar', '/?foo=bar&ticket=123'
    assert_request_url_without_ticket '/?bar=foo', '/?ticket=123&bar=foo'
    assert_request_url_without_ticket '/?foo=bar&bar=foo', '/?foo=bar&ticket=123&bar=foo'
    assert_request_url_without_ticket '/?foo=bar&bar=foo', '/?foo=bar&bar=foo'
  end

  def test_service_ticket
    @mock_request.expect :params, {}
    t = @client.service_ticket ''
    refute t
  end

  def test_service_ticket_returns_proxy_ticket
    @mock_request.expect :params, 'ticket' => 'PT-123'
    t = @client.service_ticket ''
    assert_kind_of CASClient::ProxyTicket, t
  end

  def test_service_ticket_returns_service_ticket
    @mock_request.expect :params, 'ticket' => 'ST-123'
    t = @client.service_ticket ''
    assert_kind_of CASClient::ServiceTicket, t
  end

  def test_ticket_validation
    expected = 'http://example.org/foo'

    cli = @client.client
    def cli.validate_service_ticket(t)
      def t.is_valid?() true end
      def t.user() 'me' end
    end

    get '/foo?ticket=ST-123', nil, @env
    assert last_response.redirect?
    assert_equal expected, last_response['Location']

    expected = {'username' => 'me'}
    assert_equal expected, @session[:cas_user]
  end

  def test_ticket_in_valid
    expected = 'http://example/cas/login?service=http%3A%2F%2Fexample.org%2Ffoo'

    cli = @client.client
    def cli.validate_service_ticket(t)
      def t.is_valid?() false end
    end

    get '/foo?ticket=ST-123'
    assert last_response.redirect?
    assert_equal expected, last_response['Location']
  end
end
