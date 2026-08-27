# Changelog

All notable changes to this project are documented in this file.

## [0.2.0] - 2026-08-26

### Changed

- **Breaking:** requires `omniauth ~> 2.0` and `omniauth-oauth2 ~> 1.9` (previously an
  unpinned `omniauth-oauth2`, which resolved to `omniauth 1.9` / `oauth2 1.4`). Host
  applications must upgrade to OmniAuth 2.x; Rails apps also need
  [`omniauth-rails_csrf_protection`](https://github.com/cookpad/omniauth-rails_csrf_protection)
  because OmniAuth 2 only accepts `POST` for the request phase.
- Pinned the token endpoint to `auth_scheme: :request_body`. `oauth2 2.0` changed its
  default to `:basic_auth`, which would have moved `client_id`/`client_secret` out of
  the token request body and changed what Fulfillment.com receives.
- Requires Ruby >= 3.2 (the modern `oauth2` dependency chain requires it).
- Development toolchain: Bundler 4.x, `rake ~> 13.0`, `rspec ~> 3.13`.
- Replaced Travis CI with GitHub Actions, testing Ruby 3.2 through 3.4.
- Releases are now cut from the GitHub Releases UI: publishing a `vX.Y.Z` release reruns
  the matrix, checks the tag against `version.rb`, and publishes to RubyGems.org via
  trusted publishing (OIDC, no stored API key).

### Added

- `LICENSE.txt` (MIT), now declared in the gemspec.
- A default `client_options[:site]` of `https://auth.fulfillment.com`, so the strategy
  works without a `setup` lambda. Overriding `client_options[:site]` still wins.
- Integration specs covering the request phase, the token exchange, the `redirect_uri`
  override and the auth hash.
- A weekly `bundle-audit` run, so a new advisory against the locked `oauth2`/`rack`
  chain surfaces here rather than in a consuming app.

### Fixed

- `callback_url` no longer doubles a mount prefix. The override added `script_name` to
  `callback_path`, but OmniAuth 2 moved `script_name` into `callback_path` itself, so a
  strategy mounted under a prefix (for example Devise's `/users`) would have sent
  `redirect_uri=http://host/users/users/auth/fdc/callback`.
- Resolved 39 advisories carried by the old locked dependency tree, including
  `omniauth` CVE-2015-9284 and CVE-2020-36599, `oauth2` CVE-2026-54603, `jwt`
  CVE-2026-45363, `faraday` CVE-2026-54297, and 30 against `rack 2.2.3`.
- `bin/console` required a non-existent `omniauth/fdc` file.
- Development scripts in `bin/` are no longer packaged as gem executables, and the
  committed `.gem` build artifacts are gone from the repo.

## [0.1.2] - 2020-06-29

- `callback_url` is overridden so query params from a configured `redirect_uri` are not
  sent to Fulfillment.com (#4).

## [0.1.1] - 2020-05-20

- Raised the `omniauth-oauth2` floor to 1.6 and dropped the upper version constraint.

## [0.1.0] - 2018-10-15

- Initial published strategy.

[0.2.0]: https://github.com/dropstream/omniauth-fdc/releases/tag/v0.2.0
[0.1.2]: https://rubygems.org/gems/omniauth-fdc/versions/0.1.2
[0.1.1]: https://rubygems.org/gems/omniauth-fdc/versions/0.1.1
[0.1.0]: https://rubygems.org/gems/omniauth-fdc/versions/0.1.0
