# frozen_string_literal: true

RSpec.describe OmniAuth::Strategies::Fdc do
  let(:inner_app) { ->(_env) { [200, {}, ["Hello."]] } }
  let(:strategy_options) { {} }
  let(:strategy) { described_class.new(inner_app, "client_id", "client_secret", **strategy_options) }

  def app
    described_class.new(inner_app, "client_id", "client_secret", **strategy_options)
  end

  describe "#client_options" do
    subject(:client_options) { strategy.options.client_options }

    it "points at the Fulfillment.com auth site" do
      expect(client_options.site).to eq("https://auth.fulfillment.com")
    end

    it "has the correct authorize url" do
      expect(client_options.authorize_url).to eq("/oauth/authorize")
    end

    it "has the correct token url" do
      expect(client_options.token_url).to eq("/oauth/access_token")
    end

    # oauth2 >= 2.0 defaults to :basic_auth, which would move the client
    # credentials out of the token request body.
    it "sends client credentials in the request body" do
      expect(client_options.auth_scheme).to eq(:request_body)
    end

    context "when the site is overridden" do
      let(:strategy_options) { {client_options: {site: "https://auth.staging.fulfillment.com"}} }

      it "uses the configured site" do
        expect(client_options.site).to eq("https://auth.staging.fulfillment.com")
      end
    end
  end

  describe "the request phase" do
    around do |example|
      previous = OmniAuth.config.request_validation_phase
      OmniAuth.config.request_validation_phase = proc {}
      example.run
      OmniAuth.config.request_validation_phase = previous
    end

    it "redirects to Fulfillment.com's authorize endpoint" do
      post "/auth/fdc", {}, "rack.session" => {}

      expect(last_response.status).to eq(302)
      location = URI.parse(last_response.headers["Location"])
      expect("#{location.scheme}://#{location.host}#{location.path}")
        .to eq("https://auth.fulfillment.com/oauth/authorize")
      expect(URI.decode_www_form(location.query).to_h)
        .to include("client_id" => "client_id", "response_type" => "code")
    end

    context "when a scope is configured" do
      let(:strategy_options) { {scope: "oms"} }

      it "passes the scope through to the authorize url" do
        post "/auth/fdc", {}, "rack.session" => {}

        query = URI.decode_www_form(URI.parse(last_response.headers["Location"]).query).to_h
        expect(query["scope"]).to eq("oms")
      end
    end

    context "when configured for another site" do
      let(:strategy_options) { {client_options: {site: "https://auth.staging.fulfillment.com"}} }

      it "redirects to the configured auth site" do
        post "/auth/fdc", {}, "rack.session" => {}

        expect(last_response.headers["Location"])
          .to start_with("https://auth.staging.fulfillment.com/oauth/authorize")
      end
    end
  end

  describe "the callback phase" do
    let(:session) { {"omniauth.state" => "abc123"} }
    let(:token_url) { "#{strategy.options.client_options[:site]}/oauth/access_token" }

    before do
      stub_request(:post, token_url).to_return(
        status: 200,
        body: {access_token: "token123", token_type: "Bearer"}.to_json,
        headers: {"Content-Type" => "application/json"}
      )
    end

    def complete_callback(query = "")
      post "/auth/fdc/callback#{query}",
           {"code" => "auth_code", "state" => "abc123"},
           "rack.session" => session
    end

    def token_request_body
      body = nil
      expect(WebMock).to have_requested(:post, token_url).with { |req| body = req.body; true }
      URI.decode_www_form(body).to_h
    end

    it "exchanges the code for a token with credentials in the body" do
      complete_callback

      expect(token_request_body.values_at("client_id", "client_secret"))
        .to eq(%w[client_id client_secret])
    end

    it "does not fall back to HTTP basic auth for the client credentials" do
      complete_callback

      expect(WebMock).to have_requested(:post, token_url)
        .with { |req| !req.headers.key?("Authorization") }
    end

    # PR #4: the redirect_uri sent to Fulfillment.com must not carry the callback's query params.
    it "sends a redirect_uri without query params" do
      complete_callback("?utm_source=fdc")

      expect(token_request_body["redirect_uri"]).to eq("http://example.org/auth/fdc/callback")
    end

    it "builds an auth hash carrying the token" do
      complete_callback

      credentials = last_request.env["omniauth.auth"]["credentials"]
      expect(credentials["token"]).to eq("token123")
      expect(credentials["expires"]).to be(false)
    end

    # OmniAuth's own callback_url drops SCRIPT_NAME, which would send the wrong
    # redirect_uri when the strategy is mounted under a prefix (e.g. Devise's /users).
    it "keeps the mount point in the redirect_uri" do
      post "/auth/fdc/callback",
           {"code" => "auth_code", "state" => "abc123"},
           "rack.session" => session, "SCRIPT_NAME" => "/users"

      expect(token_request_body["redirect_uri"]).to eq("http://example.org/users/auth/fdc/callback")
    end

    context "when configured for another site" do
      let(:strategy_options) { {client_options: {site: "https://auth.staging.fulfillment.com"}} }

      it "exchanges the token against the configured host" do
        complete_callback

        expect(WebMock).to have_requested(:post, "https://auth.staging.fulfillment.com/oauth/access_token")
        expect(last_request.env["omniauth.auth"]["credentials"]["token"]).to eq("token123")
      end
    end
  end

  describe "#callback_url" do
    subject(:callback_url) { strategy.callback_url }

    context "when callback_url is configured" do
      let(:strategy_options) { {callback_url: "https://app.getdropstream.com/users/auth/fdc/callback"} }

      it "uses the configured value verbatim" do
        expect(callback_url).to eq("https://app.getdropstream.com/users/auth/fdc/callback")
      end
    end

  end
end
