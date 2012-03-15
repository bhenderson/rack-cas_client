require 'rack/request'
require 'rubycas-client'

module Rack
  class CASClient
    VERSION = '1.0.0'

    attr_reader :client, :options, :request

    ##
    # options - Hash
    #           logger - Symbol, must respond to :<<
    #           verify_ssl - Bool, force ssl verification?
    #           cas_base_url - String, your CAS Server base url.
    def initialize app = nil, opts = {}
      @app = app
      @options = opts
      @client = ::CASClient::Client.new(
        cas_base_url:           options[:cas_base_url],
        force_ssl_verification: options[:verify_ssl]
      )
    end

    def app
      @app || lambda{|env|
        [200, {'Content-Type'=>'text/plain'},['logged in']]}
    end

    def call env
      dup.call! env
    end

    def call! env
      @request = Rack::Request.new env

      return app.call(env) if authenticated?

      service_url = request_url_without_ticket
      cas_login_url = client.add_service_to_login_url(service_url)

      if st = service_ticket(service_url)

        client.validate_service_ticket(st) unless st.has_been_validated?

        if st.is_valid?
          log 'ticket is valid'
          # use string because extra_attributes will always have strings as keys
          user['username'] = st.user
          user.merge!        st.extra_attributes || {}
          log "user logged as #{user.inspect}"
          redirect service_url
        else
          log 'ticket is not valid'
          user.clear # why?
          redirect cas_login_url
        end
      else
        log 'No ticket, redirecting to login server'
        redirect cas_login_url
      end
    end

    def service_ticket service_url
      ticket = request.params['ticket']
      return unless ticket
      ticket_class = ticket =~ /^PT-/ ?
                       ::CASClient::ProxyTicket :
                       ::CASClient::ServiceTicket

      st = ticket_class.new(ticket, service_url, false)
      log "User has a #{ticket_class}! #{st.inspect}"
      st
    end

    def authenticated?
      !user.empty? && log("#{user.inspect} is already authenticated")
    end

    def log msg
      return true unless logger = options[:logger]

      logger << msg
    end

    def redirect loc
      [302,
        { 'Content-Type' => 'text/plain',
          'Content-Length' => '0',
          'Location' => loc},
        ['']]
    end

    # return the request.url minus params['ticket']
    def request_url_without_ticket
      # I feel like this should be in Rack::Request
      # request['ticket'] = nil
      # request.url
      url = request.base_url + request.path
      query = request.params.dup
      query.delete 'ticket'
      query.empty? ? url : "#{url}?#{Rack::Utils.build_nested_query query}"
    end

    def session
      request.session
    end

    def user
      session[:cas_user] ||= {}
    end

  end
end
