require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Fdc < OmniAuth::Strategies::OAuth2

      option :client_options, {
        :authorize_url => '/oauth/authorize',
        :token_url => '/oauth/access_token',
      } 
      
      def callback_url
        options[:callback_url] || (full_host + script_name + callback_path)
      end

    end
  end
end
