# Omniauth::Fdc

This is an OmniAuth strategy for authenticating to [Fulfillment.com](https://www.fulfillment.com).

Requires Ruby >= 3.2, OmniAuth 2.x and `omniauth-oauth2` 1.9.x.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-fdc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-fdc

## Usage

OmniAuth 2 only accepts `POST` for the request phase. In a Rails app, add
[`omniauth-rails_csrf_protection`](https://github.com/cookpad/omniauth-rails_csrf_protection)
to your Gemfile and link to the provider with `button_to` or `link_to ..., method: :post`:

```ruby
gem 'omniauth-rails_csrf_protection'
```

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :fdc,
           'client_id', 'client_secret',
           :scope => 'oms'
end
```

The auth hash carries the token under `credentials`:

```ruby
auth = request.env['omniauth.auth']
auth['credentials']['token']
```

## Configuring

### Configure the auth host

`client_options[:site]` defaults to `https://auth.fulfillment.com`. Point it elsewhere to
authenticate against a different Fulfillment.com environment:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :fdc,
           'client_id', 'client_secret',
           :scope => 'oms',
           :client_options => { :site => 'https://auth.staging.fulfillment.com' }
end
```

Setting it from a `setup` lambda also still works, which is how apps configured the host
before the default existed:

```ruby
  :setup => ->(env) { env['omniauth.strategy'].options[:client_options][:site] = 'https://auth.fulfillment.com' }
```

### Configure the callback URL

The strategy overrides `callback_url` to drop the query string that OmniAuth would
otherwise append, because Fulfillment.com rejects a `redirect_uri` that does not match
the registered one exactly. Pass `callback_url` to override it outright:

```ruby
  :callback_url => 'https://app.example.com/users/auth/fdc/callback'
```

Otherwise it is derived from the request, including the mount prefix — a strategy mounted
under Devise's `/users` produces `https://app.example.com/users/auth/fdc/callback`.

### Client credentials in the token request

`client_options[:auth_scheme]` is pinned to `:request_body`, because Fulfillment.com
expects `client_id` and `client_secret` in the token request body. This was `oauth2` 1.x's
default; `oauth2` 2.x defaults to `:basic_auth`. Do not override it unless
Fulfillment.com starts accepting HTTP Basic auth on the token endpoint.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

Run `bundle exec bundle-audit check --update` to check the locked dependency tree against
the advisory database; CI runs the same check weekly.

## Releasing

Releases are cut from the [GitHub Releases UI](https://github.com/dropstream/omniauth-fdc/releases/new);
GitHub Actions builds and publishes the gem to [rubygems.org](https://rubygems.org) via
[RubyGems trusted publishing](https://guides.rubygems.org/trusted-publishing/), so no API
key is stored in the repo and the gemspec can keep `rubygems_mfa_required`.

1. Bump `VERSION` in `lib/omniauth-fdc/version.rb` and add a `CHANGELOG.md` section
   for it, along with a link definition for the new heading at the bottom of that file.
   Commit both on `master`.
2. Draft a new release with the target set to `master` and the tag set to the version
   prefixed with `v` — `v0.2.0`, not `0.2.0`. The prefix is stripped before comparing
   against `version.rb`; the gem version itself carries no `v`.
3. Click **Generate release notes** — the preferred method — then publish. The generated
   notes list the merged pull requests; `CHANGELOG.md` carries the curated prose and
   links back to each release.

Publishing creates the tag, which fires the `Release` workflow: it reruns the full test
matrix, refuses to continue if the tag and `version.rb` disagree, and pushes the gem.
Note that RubyGems versions are immutable — a bad release can be yanked, never replaced,
so the version bump has to be committed before the release is published.

### One-time RubyGems setup

Needed before the first release from CI, and again only if the gem is renamed or moved:
on rubygems.org open the gem -> **Trusted publishers** -> **Create**, with owner
`dropstream`, repository `omniauth-fdc`, workflow `release.yml`, and environment
`release`. The repo also needs an environment named `release`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dropstream/omniauth-fdc.

## License

Available as open source under the terms of the [MIT License](LICENSE.txt).
