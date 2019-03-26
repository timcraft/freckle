require 'noko/version'
require 'noko/errors'
require 'noko/link_header'
require 'noko/params'
require 'noko/record'
require 'net/http'
require 'json'

module Noko
  class Client
    def initialize(options = {})
      if options.key?(:access_token)
        @auth_header, @auth_value = 'Authorization', "token #{options[:access_token]}"
      else
        @auth_header, @auth_value = 'X-NokoToken', options.fetch(:token)
      end

      @user_agent = options.fetch(:user_agent) { "noko/#{VERSION} ruby/#{RUBY_VERSION}" }

      @host = 'api.nokotime.com'

      @http = Net::HTTP.new(@host, Net::HTTP.https_default_port)

      @http.use_ssl = true
    end

    def get(path, params = nil)
      request(Net::HTTP::Get.new(Params.join(path, params)))
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
              object.singleton_class.module_eval { attr_accessor :link }
              object.link = LinkHeader.parse(http_response['Link'])
            end
          end
        else
          http_response.body
        end
      when Net::HTTPBadRequest
        object = JSON.parse(http_response.body, symbolize_names: true)

        raise Error, object.fetch(:message)
      when Net::HTTPUnauthorized
        raise AuthenticationError
      else
        raise Error, "unexpected #{http_response.code} response from #{@host}"
      end
    end
  end
end
