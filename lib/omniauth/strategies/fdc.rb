require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Fdc < OmniAuth::Strategies::OAuth2

      option :client_options, {
        :authorize_url => '/oauth/authorize',
        :token_url => '/oauth/access_token',
      }        
    end
  end
end
