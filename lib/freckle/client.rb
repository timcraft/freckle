require 'freckle/errors'
require 'freckle/record'
require 'net/http'
require 'cgi'
require 'json'

module Freckle
  class Client
    def initialize(options = {})
      if options.key?(:access_token)
        @auth_header, @auth_value = 'Authorization', "token #{options[:access_token]}"
      else
        @auth_header, @auth_value = 'X-FreckleToken', options.fetch(:token)
      end

      @user_agent = options.fetch(:user_agent, 'Ruby Freckle::Client')

      @host = 'api.letsfreckle.com'

      @http = Net::HTTP.new(@host, Net::HTTP.https_default_port)

      @http.use_ssl = true
    end

    def get(path, params = nil)
      request(Net::HTTP::Get.new(request_uri(path, params)))
    end

    private

    def post(path, attributes)
      request(Net::HTTP::Post.new(path), attributes)
    end

    def put(path, attributes = nil)
      request(Net::HTTP::Put.new(path), attributes)
    end

    def delete(path)
      request(Net::HTTP::Delete.new(path))
    end

    def request(http_request, body_object = nil)
      http_request['User-Agent'] = @user_agent
      http_request[@auth_header] = @auth_value

      if body_object
        http_request['Content-Type'] = 'application/json'
        http_request.body = JSON.generate(body_object)
      end

      parse(@http.request(http_request))
    end

    def parse(http_response)
      case http_response
      when Net::HTTPNoContent
        :no_content
      when Net::HTTPSuccess
        if http_response['Content-Type'] && http_response['Content-Type'].split(';').first == 'application/json'
          JSON.parse(http_response.body, symbolize_names: true, object_class: Record).tap do |object|
            if http_response['Link']
              store_next_and_last_page_links(http_response, object)
            end
          end
        else
          http_response.body
        end
      when Net::HTTPBadRequest
        object = JSON.parse(http_response.body, symbolize_names: true)

        raise Error, "freckle api error: #{object.fetch(:message)}"
      when Net::HTTPUnauthorized
        raise AuthenticationError
      else
        raise Error, "freckle api error: unexpected #{http_response.code} response from #{@host}"
      end
    end

    def request_uri(path, params = nil)
      return path if params.nil? || params.empty?

      path + '?' + params.map { |k, v| "#{escape(k)}=#{array_escape(v)}" }.join('&')
    end

    def array_escape(object)
      Array(object).map { |value| escape(value) }.join(',')
    end

    def escape(component)
      CGI.escape(component.to_s)
    end

    def store_next_and_last_page_links(http_response, object)
      ["next", "last"].inject({}) do |result, value|
        if result[value] = http_response['Link'][/<([^>]+)>; rel="#{value}"/, 1]
          object.singleton_class.module_eval { attr_accessor :"#{value}_page" }
          object.send("#{value}_page=", URI.parse(result[value]).request_uri)
        end
        result
      end
    end
  end
end
