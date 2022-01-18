source "https://rubygems.org"

# Specify your gem's dependencies in ruby-sigstore.gemspec
gemspec
gem "config", "~> 3.1.0"
gem "faraday_middleware", "~> 1.0.0"
gem "oa-openid", "~> 0.0.2"
gem "omniauth-openid", "~> 2.0.1"
gem "ruby-openid-apps-discovery", "~> 1.2.0"
gem "json-jwt", "~> 1.13.0"
gem 'net-smtp', require: false

group :development do
  gem "rubocop", "~> 0.80.1"
  gem "rubocop-performance", "~> 1.5.2"
  gem "rake", "~> 12.0"
end

group :test do
  gem "test-unit", "~> 3.0"
  gem "webmock", "~> 3.0"
end

group :development, :test do
  gem "byebug"
end
