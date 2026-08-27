# frozen_string_literal: true

require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Fdc < OmniAuth::Strategies::OAuth2
      DEFAULT_SITE = 'https://auth.fulfillment.com'

      option :client_options, {
        :site => DEFAULT_SITE,
        :authorize_url => '/oauth/authorize',
        :token_url => '/oauth/access_token',
        # oauth2 2.x defaults to :basic_auth; Fulfillment.com expects the client
        # credentials in the token request body, which was the oauth2 1.x default.
        :auth_scheme => :request_body
      }

      # OmniAuth::Strategy#callback_url appends the callback request's own query
      # string, which would send those params to Fulfillment.com as part of
      # redirect_uri and break the exchange. Note that omniauth 2's `callback_path`
      # already carries SCRIPT_NAME, so mount prefixes must not be added again.
      def callback_url
        options[:callback_url] || (full_host + callback_path)
      end
    end
  end
end
